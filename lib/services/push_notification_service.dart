import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../data/hive_boxes.dart';
import 'hive_lifecycle_service.dart';
import 'notification_service.dart';

const String pushDeviceIdKey = 'pushDeviceId';
const String pushRegisteredUsersKey = 'pushRegisteredUsers';

enum PushPermissionStatus { authorized, provisional, denied, unknown }

class PushMessageData {
  const PushMessageData({
    required this.data,
    this.title,
    this.body,
  });

  final Map<String, dynamic> data;
  final String? title;
  final String? body;
}

abstract class PushMessagingClient {
  Future<PushPermissionStatus> requestPermission();
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;
  Stream<PushMessageData> get onMessage;
  Stream<PushMessageData> get onMessageOpenedApp;
  Future<PushMessageData?> getInitialMessage();
}

class PushAuthUser {
  const PushAuthUser(this.uid);
  final String uid;
}

abstract class PushAuthClient {
  PushAuthUser? get currentUser;
  Stream<PushAuthUser?> get authStateChanges;
}

class FirebasePushAuthClient implements PushAuthClient {
  FirebasePushAuthClient({FirebaseAuth? auth}) : _auth = auth;

  final FirebaseAuth? _auth;
  FirebaseAuth get _instance => _auth ?? FirebaseAuth.instance;

  PushAuthUser? _map(User? user) {
    if (user == null || user.isAnonymous || user.providerData.isEmpty) {
      return null;
    }
    return PushAuthUser(user.uid);
  }

  @override
  PushAuthUser? get currentUser => _map(_instance.currentUser);

  @override
  Stream<PushAuthUser?> get authStateChanges =>
      _instance.authStateChanges().map(_map);
}

class FirebasePushMessagingClient implements PushMessagingClient {
  FirebasePushMessagingClient({FirebaseMessaging? messaging})
      : _messaging = messaging;

  final FirebaseMessaging? _messaging;
  FirebaseMessaging get _instance => _messaging ?? FirebaseMessaging.instance;

  @override
  Future<PushPermissionStatus> requestPermission() async {
    final settings = await _instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await _instance.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized => PushPermissionStatus.authorized,
      AuthorizationStatus.provisional => PushPermissionStatus.provisional,
      AuthorizationStatus.denied => PushPermissionStatus.denied,
      AuthorizationStatus.notDetermined => PushPermissionStatus.unknown,
    };
  }

  PushMessageData _map(RemoteMessage message) => PushMessageData(
        data: Map<String, dynamic>.from(message.data),
        title: message.notification?.title,
        body: message.notification?.body,
      );

  @override
  Future<String?> getToken() => _instance.getToken();

  @override
  Stream<String> get onTokenRefresh => _instance.onTokenRefresh;

  @override
  Stream<PushMessageData> get onMessage =>
      FirebaseMessaging.onMessage.map(_map);

  @override
  Stream<PushMessageData> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map(_map);

  @override
  Future<PushMessageData?> getInitialMessage() async {
    final message = await _instance.getInitialMessage();
    return message == null ? null : _map(message);
  }
}

class PushDeviceRegistration {
  const PushDeviceRegistration({
    required this.fcmToken,
    required this.platform,
    required this.appVersion,
    required this.includeCreatedAt,
  });

  final String fcmToken;
  final String platform;
  final String appVersion;
  final bool includeCreatedAt;
}

abstract class PushRegistrationStore {
  Future<void> registerDevice({
    required String uid,
    required String deviceId,
    required PushDeviceRegistration registration,
  });

  Future<void> disableDevice({
    required String uid,
    required String deviceId,
  });

  Future<bool> getSharedDogSessionCreated(String uid);
  Future<void> setSharedDogSessionCreated(String uid, bool enabled);
}

class FirestorePushRegistrationStore implements PushRegistrationStore {
  FirestorePushRegistrationStore({FirebaseFirestore? firestore})
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;
  FirebaseFirestore get _instance => _firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _device(String uid, String id) =>
      _instance.collection('users').doc(uid).collection('devices').doc(id);

  @override
  Future<void> registerDevice({
    required String uid,
    required String deviceId,
    required PushDeviceRegistration registration,
  }) {
    final data = <String, dynamic>{
      'fcmToken': registration.fcmToken,
      'platform': registration.platform,
      'enabled': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
      'appVersion': registration.appVersion,
    };
    if (registration.includeCreatedAt) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    return _device(uid, deviceId).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> disableDevice({required String uid, required String deviceId}) {
    return _device(uid, deviceId).set({
      'enabled': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<bool> getSharedDogSessionCreated(String uid) async {
    final snapshot = await _instance.collection('users').doc(uid).get();
    final preferences = snapshot.data()?['notificationPreferences'];
    if (preferences is Map<String, dynamic>) {
      return preferences['sharedDogSessionCreated'] as bool? ?? true;
    }
    if (preferences is Map) {
      return preferences['sharedDogSessionCreated'] as bool? ?? true;
    }
    return true;
  }

  @override
  Future<void> setSharedDogSessionCreated(String uid, bool enabled) {
    return _instance.collection('users').doc(uid).update({
      'notificationPreferences.sharedDogSessionCreated': enabled,
    });
  }
}

abstract class PushInstallationStore {
  Future<String> getOrCreateDeviceId();
  bool wasRegisteredFor(String uid);
  Future<void> markRegisteredFor(String uid);
}

class HivePushInstallationStore implements PushInstallationStore {
  HivePushInstallationStore({Box<dynamic>? box, Uuid uuid = const Uuid()})
      : _box = box ?? HiveLifecycleService.getBox<dynamic>(appSettingsBoxName),
        _uuid = uuid;

  final Box<dynamic> _box;
  final Uuid _uuid;

  @override
  Future<String> getOrCreateDeviceId() async {
    final existing = (_box.get(pushDeviceIdKey) as String?)?.trim();
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _uuid.v4();
    await _box.put(pushDeviceIdKey, id);
    return id;
  }

  Set<String> get _registeredUsers =>
      ((_box.get(pushRegisteredUsersKey) as List?) ?? const <dynamic>[])
          .whereType<String>()
          .toSet();

  @override
  bool wasRegisteredFor(String uid) => _registeredUsers.contains(uid);

  @override
  Future<void> markRegisteredFor(String uid) async {
    final users = _registeredUsers..add(uid);
    await _box.put(pushRegisteredUsersKey, users.toList(growable: false));
  }
}

typedef AppVersionProvider = Future<String> Function();

class PushNotificationService {
  PushNotificationService({
    PushMessagingClient? messaging,
    PushRegistrationStore? registrationStore,
    PushInstallationStore? installationStore,
    AppNotificationService? notificationService,
    PushAuthClient? auth,
    AppVersionProvider? appVersionProvider,
    String? platform,
  })  : _messaging = messaging ?? FirebasePushMessagingClient(),
        _registrationStore =
            registrationStore ?? FirestorePushRegistrationStore(),
        _installationStore = installationStore ?? HivePushInstallationStore(),
        _notificationService =
            notificationService ?? NotificationService.instance,
        _auth = auth ?? FirebasePushAuthClient(),
        _appVersionProvider = appVersionProvider ?? _readAppVersion,
        _platform = platform ?? Platform.operatingSystem;

  static final PushNotificationService instance = PushNotificationService();

  final PushMessagingClient _messaging;
  final PushRegistrationStore _registrationStore;
  final PushInstallationStore _installationStore;
  final AppNotificationService _notificationService;
  final PushAuthClient _auth;
  final AppVersionProvider _appVersionProvider;
  final String _platform;

  bool _started = false;
  String? _activeUid;
  String? _deviceId;
  String? _lastRegistrationSignature;
  Future<void>? _registrationAttempt;
  StreamSubscription<PushAuthUser?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<PushMessageData>? _messageSubscription;
  StreamSubscription<PushMessageData>? _openedSubscription;
  Map<String, dynamic>? lastOpenedNotificationData;

  static Future<String> _readAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _tokenSubscription = _messaging.onTokenRefresh.listen(
      (token) => unawaited(_registerToken(token)),
    );
    _messageSubscription = _messaging.onMessage.listen(_showForegroundMessage);
    _openedSubscription =
        _messaging.onMessageOpenedApp.listen(_retainOpenedMessage);
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _retainOpenedMessage(initial);
    _authSubscription = _auth.authStateChanges.listen(
      (user) => unawaited(_handleAuthUser(user)),
    );
    await _handleAuthUser(_auth.currentUser);
  }

  Future<void> _handleAuthUser(PushAuthUser? user) async {
    if (user == null) {
      _activeUid = null;
      _lastRegistrationSignature = null;
      return;
    }
    if (_activeUid != user.uid) {
      final previousUid = _activeUid;
      if (previousUid != null) {
        try {
          final deviceId =
              _deviceId ??= await _installationStore.getOrCreateDeviceId();
          await _registrationStore.disableDevice(
            uid: previousUid,
            deviceId: deviceId,
          );
        } catch (error) {
          debugPrint('[PUSH] failed to disable previous user device: $error');
        }
      }
      _activeUid = user.uid;
      _lastRegistrationSignature = null;
    }
    await registerCurrentDevice();
  }

  Future<void> registerCurrentDevice() async {
    final existingAttempt = _registrationAttempt;
    if (existingAttempt != null) return existingAttempt;
    final attempt = _performCurrentDeviceRegistration();
    _registrationAttempt = attempt;
    try {
      await attempt;
    } finally {
      if (identical(_registrationAttempt, attempt)) {
        _registrationAttempt = null;
      }
    }
  }

  Future<void> _performCurrentDeviceRegistration() async {
    final uid = _activeUid;
    if (uid == null) return;
    final permission = await _messaging.requestPermission();
    if (permission != PushPermissionStatus.authorized &&
        permission != PushPermissionStatus.provisional) {
      return;
    }
    final token = (await _messaging.getToken())?.trim();
    if (token == null || token.isEmpty) return;
    await _registerToken(token);
  }

  Future<void> _registerToken(String token) async {
    final uid = _activeUid;
    final normalizedToken = token.trim();
    if (uid == null || normalizedToken.isEmpty) return;
    final deviceId =
        _deviceId ??= await _installationStore.getOrCreateDeviceId();
    final appVersion = await _appVersionProvider();
    final signature = '$uid|$deviceId|$normalizedToken|$_platform|$appVersion';
    if (_lastRegistrationSignature == signature) return;
    _lastRegistrationSignature = signature;
    try {
      await _registrationStore.registerDevice(
        uid: uid,
        deviceId: deviceId,
        registration: PushDeviceRegistration(
          fcmToken: normalizedToken,
          platform: _platform,
          appVersion: appVersion,
          includeCreatedAt: !_installationStore.wasRegisteredFor(uid),
        ),
      );
      await _installationStore.markRegisteredFor(uid);
    } catch (_) {
      if (_lastRegistrationSignature == signature) {
        _lastRegistrationSignature = null;
      }
      rethrow;
    }
  }

  Future<void> deactivateCurrentUser() async {
    final uid = _activeUid ?? _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    final deviceId =
        _deviceId ??= await _installationStore.getOrCreateDeviceId();
    await _registrationStore.disableDevice(uid: uid, deviceId: deviceId);
    _activeUid = null;
    _lastRegistrationSignature = null;
  }

  Future<bool> getSharedDogSessionCreatedPreference(String uid) =>
      _registrationStore.getSharedDogSessionCreated(uid);

  Future<void> setSharedDogSessionCreatedPreference(
    String uid,
    bool enabled,
  ) =>
      _registrationStore.setSharedDogSessionCreated(uid, enabled);

  void _showForegroundMessage(PushMessageData message) {
    final title = message.title?.trim();
    final body = message.body?.trim();
    if (title == null || title.isEmpty || body == null || body.isEmpty) return;
    unawaited(_notificationService.showSharedDogSessionNotification(
      title: title,
      body: body,
    ));
  }

  void _retainOpenedMessage(PushMessageData message) {
    lastOpenedNotificationData = Map<String, dynamic>.from(message.data);
    debugPrint(
      '[PUSH] opened notification type=${message.data['type']} '
      'dogId=${message.data['dogId']} sessionId=${message.data['sessionId']}',
    );
  }

  @visibleForTesting
  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _openedSubscription?.cancel();
  }
}
