import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('diagnostic: share invites do not currently have an FCM push trigger',
      () async {
    final functionsSource = await File('functions/src/index.ts').readAsString();
    final notificationSource =
        await File('lib/services/notification_service.dart').readAsString();

    expect(functionsSource, isNot(contains('shareInvites')));
    expect(functionsSource, isNot(contains('getMessaging')));
    expect(functionsSource, isNot(contains('.send(')));
    expect(notificationSource, isNot(contains('FirebaseMessaging')));
  });
}
