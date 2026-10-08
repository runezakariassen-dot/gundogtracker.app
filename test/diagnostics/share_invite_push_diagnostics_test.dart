import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('diagnostic: shared dog session push architecture is wired',
      () async {
    final pubspecSource = await File('pubspec.yaml').readAsString();
    final functionsSource = await File('functions/src/index.ts').readAsString();
    final pushServiceSource =
        await File('lib/services/push_notification_service.dart')
            .readAsString();
    final firestoreRules = await File('firestore.rules').readAsString();
    final sharedNotificationFile =
        File('functions/src/shared_dog_session_notifications.ts');

    expect(pubspecSource, contains('firebase_messaging:'));

    expect(pushServiceSource, contains('class PushNotificationService'));
    expect(pushServiceSource, contains('onTokenRefresh'));
    expect(
      pushServiceSource,
      contains("collection('users').doc(uid).collection('devices').doc(id)"),
    );

    expect(await sharedNotificationFile.exists(), isTrue);
    expect(functionsSource, contains('onSharedDogSessionCreated'));
    expect(
      functionsSource,
      contains('document("dogs/{dogId}/sessions/{sessionId}")'),
    );
    expect(
      functionsSource,
      contains('from "./shared_dog_session_notifications"'),
    );
    expect(functionsSource, contains('getMessaging'));
    expect(functionsSource, contains('sendEachForMulticast'));

    expect(firestoreRules, contains('match /notificationDeliveries/{deliveryId}'));
    expect(firestoreRules, contains('allow read, write: if false;'));
    expect(firestoreRules, contains('match /users/{userId}'));
    expect(firestoreRules, contains('match /devices/{deviceId}'));
    expect(
      firestoreRules,
      contains('allow read, create, update, delete: if isSignedIn()'),
    );
    expect(firestoreRules, contains('request.auth.uid == userId'));
  });
}
