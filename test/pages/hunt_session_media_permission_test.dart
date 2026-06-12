import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/hunt_session_page.dart';

void main() {
  group('canAddMediaInSessionContext', () {
    test('allows media when explicit media access is granted', () {
      final result = canAddMediaInSessionContext(
        hasMediaAccess: true,
        isEditMode: false,
        editingSessionDogId: null,
        selectedDogId: null,
      );

      expect(result, isTrue);
    });

    test('allows media in new session when a dog is selected', () {
      final result = canAddMediaInSessionContext(
        hasMediaAccess: false,
        isEditMode: false,
        editingSessionDogId: null,
        selectedDogId: 'dog-1',
      );

      expect(result, isTrue);
    });

    test('denies media in new session when no dog is selected', () {
      final result = canAddMediaInSessionContext(
        hasMediaAccess: false,
        isEditMode: false,
        editingSessionDogId: null,
        selectedDogId: null,
      );

      expect(result, isFalse);
    });

    test(
        'allows media in edit mode for the same dog even if access check fails',
        () {
      final result = canAddMediaInSessionContext(
        hasMediaAccess: false,
        isEditMode: true,
        editingSessionDogId: 'dog-1',
        selectedDogId: 'dog-1',
      );

      expect(result, isTrue);
    });

    test(
        'denies media in edit mode when selected dog does not match session dog',
        () {
      final result = canAddMediaInSessionContext(
        hasMediaAccess: false,
        isEditMode: true,
        editingSessionDogId: 'dog-1',
        selectedDogId: 'dog-2',
      );

      expect(result, isFalse);
    });

    test('denies media in edit mode when dog ids are missing', () {
      final result = canAddMediaInSessionContext(
        hasMediaAccess: false,
        isEditMode: true,
        editingSessionDogId: null,
        selectedDogId: null,
      );

      expect(result, isFalse);
    });
  });
}
