import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Firestore Track metadata is member-readable and manager create-only',
      () {
    final rules = File('firestore.rules').readAsStringSync();
    final block = _blockFor(rules, 'match /tracks/{trackId}');

    expect(block, contains('allow read: if isDogMember(dogId);'));
    expect(block, contains('allow create: if canManageDogMedia(dogId)'));
    expect(block, isNot(contains('allow update')));
    expect(block, isNot(contains('allow delete')));
  });

  test('Storage raw Track is member-readable and manager create-only', () {
    final rules = File('storage.rules').readAsStringSync();
    final block = _blockFor(
      rules,
      'match /dogs/{dogId}/tracks/{trackId}/track.json',
    );

    expect(block, contains('allow read: if activeMembership(dogId);'));
    expect(block, contains('allow create: if activeMembership(dogId)'));
    expect(
      block,
      contains("activeRole(dogId) in ['owner', 'editor', 'admin']"),
    );
    expect(block, isNot(contains('allow update')));
    expect(block, isNot(contains('allow delete')));
  });
}

String _blockFor(String rules, String marker) {
  final start = rules.indexOf(marker);
  if (start < 0) throw StateError('Missing rules block: $marker');
  final nextMatch = rules.indexOf('\n      match /', start + marker.length);
  return rules.substring(start, nextMatch < 0 ? rules.length : nextMatch);
}
