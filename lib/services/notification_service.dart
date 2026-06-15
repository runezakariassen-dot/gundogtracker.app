import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

abstract class AppNotificationService {
  Future<void> init();

  Future<void> scheduleBirthdayReminder({
    required DateTime? birthDate,
    required String title,
    required String body,
    int hour,
    int minute,
  });

  Future<void> showGoalReachedNotification({
    required int goal,
    required String title,
    required String body,
  });
}

abstract class LocalNotificationsClient {
  Future<void> initialize(InitializationSettings settings);

  Future<void> requestPermissions();

  Future<void> show({
    required int id,
    required String title,
    required String body,
    required NotificationDetails details,
  });

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required NotificationDetails details,
  });

  Future<void> cancel(int id);
}

class FlutterLocalNotificationsClient implements LocalNotificationsClient {
  FlutterLocalNotificationsClient()
      : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> initialize(InitializationSettings settings) {
    return _plugin.initialize(settings);
  }

  @override
  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required NotificationDetails details,
  }) {
    return _plugin.show(id, title, body, details);
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required NotificationDetails details,
  }) {
    return _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  @override
  Future<void> cancel(int id) {
    return _plugin.cancel(id);
  }
}

class NotificationService implements AppNotificationService {
  NotificationService({LocalNotificationsClient? client})
      : _client = client ?? FlutterLocalNotificationsClient();

  static final NotificationService instance = NotificationService();

  static const int birthdayNotificationId = 3001;
  static const int goalNotificationBaseId = 4000;

  final LocalNotificationsClient _client;
  bool _isInitialized = false;
  bool _isTimezoneInitialized = false;

  @override
  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    try {
      if (!_isTimezoneInitialized) {
        tz_data.initializeTimeZones();
        _isTimezoneInitialized = true;
      }
      await _client.initialize(settings);
      await _client.requestPermissions();
      _isInitialized = true;
    } catch (error, stackTrace) {
      debugPrint('[NOTIFICATION] init failed: $error');
      debugPrint(stackTrace.toString());
    }
  }

  @override
  Future<void> scheduleBirthdayReminder({
    required DateTime? birthDate,
    required String title,
    required String body,
    int hour = 9,
    int minute = 0,
  }) async {
    await init();

    try {
      await _client.cancel(birthdayNotificationId);

      if (birthDate == null) {
        return;
      }

      final now = DateTime.now();
      var trigger =
          DateTime(now.year, birthDate.month, birthDate.day, hour, minute);
      if (!trigger.isAfter(now)) {
        trigger = DateTime(
          now.year + 1,
          birthDate.month,
          birthDate.day,
          hour,
          minute,
        );
      }

      await _client.schedule(
        id: birthdayNotificationId,
        title: title,
        body: body,
        scheduledDate: trigger,
        details: _defaultDetails,
      );
    } catch (error, stackTrace) {
      debugPrint('[NOTIFICATION] birthday schedule failed: $error');
      debugPrint(stackTrace.toString());
    }
  }

  @override
  Future<void> showGoalReachedNotification({
    required int goal,
    required String title,
    required String body,
  }) async {
    await init();

    try {
      final id = goalNotificationBaseId + goal;
      await _client.show(
        id: id,
        title: title,
        body: body,
        details: _defaultDetails,
      );
    } catch (error, stackTrace) {
      debugPrint('[NOTIFICATION] goal show failed: $error');
      debugPrint(stackTrace.toString());
    }
  }

  NotificationDetails get _defaultDetails {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'jakthund_local_notifications',
        'Local notifications',
        channelDescription: 'Birthday and goal reached reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
  }
}
