import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/services/notification_service.dart';
import 'package:jakthund_app/services/push_notification_service.dart';

class _FakeMessaging implements PushMessagingClient {
  PushPermissionStatus permission = PushPermissionStatus.authorized;
  String? token = 'token-1';
  PushMessageData? initialMessage;
  Object? initialMessageError;
  int initialMessageCalls = 0;
  int tokenRefreshGetterCalls = 0;
  int messageGetterCalls = 0;
  int openedGetterCalls = 0;
  final tokenController = StreamController<String>.broadcast();
  final messageController = StreamController<PushMessageData>.broadcast();
  final openedController = StreamController<PushMessageData>.broadcast();

  @override
  Future<String?> getToken() async => token;

  @override
  Future<PushMessageData?> getInitialMessage() async {
    initialMessageCalls++;
    final error = initialMessageError;
    if (error != null) throw error;
    return initialMessage;
  }

  @override
  Stream<PushMessageData> get onMessage {
    messageGetterCalls++;
    return messageController.stream;
  }

  @override
  Stream<PushMessageData> get onMessageOpenedApp {
    openedGetterCalls++;
    return openedController.stream;
  }

  @override
  Stream<String> get onTokenRefresh {
    tokenRefreshGetterCalls++;
    return tokenController.stream;
  }

  @override
  Future<PushPermissionStatus> requestPermission() async => permission;

  Future<void> close() async {
    await tokenController.close();
    await messageController.close();
    await openedController.close();
  }
}

class _FakeAuth implements PushAuthClient {
  _FakeAuth(String? uid) : _current = uid == null ? null : PushAuthUser(uid);

  PushAuthUser? _current;
  final controller = StreamController<PushAuthUser?>.broadcast();
  int streamGetterCalls = 0;
  bool emitCurrentOnListen = false;

  @override
  PushAuthUser? get currentUser => _current;

  @override
  Stream<PushAuthUser?> get authStateChanges {
    streamGetterCalls++;
    if (emitCurrentOnListen) {
      return (() async* {
        yield _current;
        yield* controller.stream;
      })();
    }
    return controller.stream;
  }

  void setUser(String? uid) {
    _current = uid == null ? null : PushAuthUser(uid);
    controller.add(_current);
  }
}

class _RegistrationCall {
  const _RegistrationCall(this.uid, this.deviceId, this.registration);
  final String uid;
  final String deviceId;
  final PushDeviceRegistration registration;
}

class _FakeStore implements PushRegistrationStore {
  final registrations = <_RegistrationCall>[];
  final disabled = <({String uid, String deviceId})>[];
  final preferences = <String, bool>{};
  final preferenceWrites = <({String uid, bool enabled})>[];

  @override
  Future<void> registerDevice({
    required String uid,
    required String deviceId,
    required PushDeviceRegistration registration,
  }) async {
    registrations.add(_RegistrationCall(uid, deviceId, registration));
  }

  @override
  Future<void> disableDevice({
    required String uid,
    required String deviceId,
  }) async {
    disabled.add((uid: uid, deviceId: deviceId));
  }

  @override
  Future<bool> getSharedDogSessionCreated(String uid) async =>
      preferences[uid] ?? true;

  @override
  Future<void> setSharedDogSessionCreated(String uid, bool enabled) async {
    preferences[uid] = enabled;
    preferenceWrites.add((uid: uid, enabled: enabled));
  }
}

class _FakeInstallationStore implements PushInstallationStore {
  String deviceId = 'device-1';
  final registeredUsers = <String>{};

  @override
  Future<String> getOrCreateDeviceId() async => deviceId;

  @override
  Future<void> markRegisteredFor(String uid) async {
    registeredUsers.add(uid);
  }

  @override
  bool wasRegisteredFor(String uid) => registeredUsers.contains(uid);
}

class _FakeNotificationService implements AppNotificationService {
  final shown = <({String title, String body})>[];

  @override
  Future<void> init() async {}

  @override
  Future<void> scheduleBirthdayReminder({
    required DateTime? birthDate,
    required String title,
    required String body,
    int hour = 9,
    int minute = 0,
  }) async {}

  @override
  Future<void> showGoalReachedNotification({
    required int goal,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> showSharedDogSessionNotification({
    required String title,
    required String body,
  }) async {
    shown.add((title: title, body: body));
  }
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeMessaging messaging;
  late _FakeAuth auth;
  late _FakeStore store;
  late _FakeInstallationStore installation;
  late _FakeNotificationService notifications;
  late PushNotificationService service;

  setUp(() {
    messaging = _FakeMessaging();
    auth = _FakeAuth('user-a');
    store = _FakeStore();
    installation = _FakeInstallationStore();
    notifications = _FakeNotificationService();
    service = PushNotificationService(
      messaging: messaging,
      auth: auth,
      registrationStore: store,
      installationStore: installation,
      notificationService: notifications,
      appVersionProvider: () async => '1.0.14+1',
      platform: 'ios',
    );
  });

  tearDown(() async {
    await service.dispose();
    await messaging.close();
    await auth.controller.close();
  });

  test('first registration writes token and device metadata', () async {
    await service.start();

    expect(store.registrations, hasLength(1));
    final call = store.registrations.single;
    expect(call.uid, 'user-a');
    expect(call.deviceId, 'device-1');
    expect(call.registration.fcmToken, 'token-1');
    expect(call.registration.platform, 'ios');
    expect(call.registration.appVersion, '1.0.14+1');
    expect(call.registration.includeCreatedAt, isTrue);
  });

  test('successful initial message setup installs all listeners', () async {
    messaging.initialMessage = const PushMessageData(
      data: {
        'type': 'sharedDogSessionCreated',
        'dogId': 'dog-1',
        'sessionId': 'session-1',
      },
    );

    await service.start();

    expect(messaging.initialMessageCalls, 1);
    expect(auth.streamGetterCalls, 1);
    expect(messaging.tokenRefreshGetterCalls, 1);
    expect(messaging.messageGetterCalls, 1);
    expect(messaging.openedGetterCalls, 1);
    expect(service.lastOpenedNotificationData?['sessionId'], 'session-1');
  });

  test('initial message failure does not block listeners or registration',
      () async {
    messaging.initialMessageError = StateError('initial message failed');

    await service.start();

    expect(messaging.initialMessageCalls, 1);
    expect(auth.streamGetterCalls, 1);
    expect(messaging.tokenRefreshGetterCalls, 1);
    expect(messaging.messageGetterCalls, 1);
    expect(messaging.openedGetterCalls, 1);
    expect(store.registrations, hasLength(1));

    await service.start();
    expect(messaging.initialMessageCalls, 1);
    expect(auth.streamGetterCalls, 1);
    expect(messaging.tokenRefreshGetterCalls, 1);
  });

  test('token refresh updates the same device id', () async {
    await service.start();
    messaging.tokenController.add('token-2');
    await _flush();

    expect(store.registrations, hasLength(2));
    expect(store.registrations.last.deviceId, 'device-1');
    expect(store.registrations.last.registration.fcmToken, 'token-2');
    expect(store.registrations.last.registration.includeCreatedAt, isFalse);
  });

  test('missing token does not write an invalid device record', () async {
    messaging.token = null;
    await service.start();
    expect(store.registrations, isEmpty);
  });

  test('logout disables the old user device', () async {
    await service.start();
    await service.deactivateCurrentUser();
    auth.setUser(null);
    await _flush();

    expect(store.disabled, [(uid: 'user-a', deviceId: 'device-1')]);
  });

  test('user switch disables old user and registers new user', () async {
    await service.start();
    auth.setUser('user-b');
    await _flush();

    expect(store.disabled, [(uid: 'user-a', deviceId: 'device-1')]);
    expect(store.registrations.last.uid, 'user-b');
    expect(store.registrations.last.deviceId, 'device-1');
  });

  test('preference defaults to true when missing', () async {
    expect(
      await service.getSharedDogSessionCreatedPreference('user-a'),
      isTrue,
    );
    expect(store.preferenceWrites, isEmpty);
  });

  test('existing false preference is preserved', () async {
    store.preferences['user-a'] = false;
    expect(
      await service.getSharedDogSessionCreatedPreference('user-a'),
      isFalse,
    );
    expect(store.preferenceWrites, isEmpty);
  });

  test('preference update writes the correct user field', () async {
    await service.setSharedDogSessionCreatedPreference('user-a', false);
    expect(store.preferenceWrites, [(uid: 'user-a', enabled: false)]);
  });

  test('repeated start does not add duplicate listeners or writes', () async {
    auth.emitCurrentOnListen = true;
    await service.start();
    await service.start();
    await _flush();

    expect(auth.streamGetterCalls, 1);
    expect(messaging.tokenRefreshGetterCalls, 1);
    expect(messaging.messageGetterCalls, 1);
    expect(messaging.openedGetterCalls, 1);
    expect(store.registrations, hasLength(1));
  });

  test('foreground message is shown through NotificationService', () async {
    await service.start();
    messaging.messageController.add(const PushMessageData(
      data: {
        'type': 'sharedDogSessionCreated',
        'dogId': 'dog-1',
        'sessionId': 'session-1',
      },
      title: 'GundogTracker',
      body: 'Ny økt registrert for Zoë',
    ));
    await _flush();

    expect(notifications.shown, [
      (title: 'GundogTracker', body: 'Ny økt registrert for Zoë'),
    ]);
  });
}
