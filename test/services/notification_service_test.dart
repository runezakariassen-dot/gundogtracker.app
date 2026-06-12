import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/services/notification_service.dart';

class _FakeLocalNotificationsClient implements LocalNotificationsClient {
  int initializeCalls = 0;
  int requestPermissionCalls = 0;
  final List<int> canceledIds = <int>[];
  final List<({int id, DateTime scheduledDate, String title, String body})>
      schedules = <({int id, DateTime scheduledDate, String title, String body})>[];
  final List<({int id, String title, String body})> shown =
      <({int id, String title, String body})>[];

  @override
  Future<void> initialize(InitializationSettings settings) async {
    initializeCalls += 1;
  }

  @override
  Future<void> requestPermissions() async {
    requestPermissionCalls += 1;
  }

  @override
  Future<void> cancel(int id) async {
    canceledIds.add(id);
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required NotificationDetails details,
  }) async {
    schedules.add((
      id: id,
      scheduledDate: scheduledDate,
      title: title,
      body: body,
    ));
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required NotificationDetails details,
  }) async {
    shown.add((id: id, title: title, body: body));
  }
}

void main() {
  test('scheduleBirthdayReminder schedules next birthday at default time', () async {
    final client = _FakeLocalNotificationsClient();
    final service = NotificationService(client: client);

    await service.scheduleBirthdayReminder(
      birthDate: DateTime(2000, 12, 24),
      title: 'Gratulerer med dagen!',
      body: 'Vi ønsker deg en fantastisk dag 🎉',
    );

    expect(client.initializeCalls, 1);
    expect(client.requestPermissionCalls, 1);
    expect(client.canceledIds, contains(NotificationService.birthdayNotificationId));
    expect(client.schedules, hasLength(1));
    expect(client.schedules.single.id, NotificationService.birthdayNotificationId);
    expect(client.schedules.single.scheduledDate.hour, 9);
    expect(client.schedules.single.scheduledDate.minute, 0);
  });

  test('scheduleBirthdayReminder with null birthdate cancels existing schedule only',
      () async {
    final client = _FakeLocalNotificationsClient();
    final service = NotificationService(client: client);

    await service.scheduleBirthdayReminder(
      birthDate: null,
      title: 'Gratulerer med dagen!',
      body: 'Vi ønsker deg en fantastisk dag 🎉',
    );

    expect(client.canceledIds, [NotificationService.birthdayNotificationId]);
    expect(client.schedules, isEmpty);
  });

  test('showGoalReachedNotification uses deterministic id per goal', () async {
    final client = _FakeLocalNotificationsClient();
    final service = NotificationService(client: client);

    await service.showGoalReachedNotification(
      goal: 25,
      title: 'Du har nådd målet ditt!',
      body: 'Sterkt jobbet - fortsett det gode arbeidet 🎯',
    );

    expect(client.shown, hasLength(1));
    expect(
      client.shown.single.id,
      NotificationService.goalNotificationBaseId + 25,
    );
  });
}
