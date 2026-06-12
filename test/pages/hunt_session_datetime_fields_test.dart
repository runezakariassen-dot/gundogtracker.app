// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('Hunt Session DateTime Formatters', () {
    test('date formatter returns dd.MM.yyyy format for Norwegian locale', () {
      // Arrange
      final testDate = DateTime(2025, 9, 28, 10, 45);

      // Act
      final formatted = DateFormat.yMd('nb_NO').format(testDate);

      // Assert
      expect(formatted, contains('28'));
      expect(formatted, contains('9'));
      expect(formatted, contains('2025'));
    });

    test('time formatter returns HH:mm format for Norwegian locale', () {
      // Arrange
      final testDate = DateTime(2025, 9, 28, 10, 45);

      // Act
      final formatted = DateFormat.Hm('nb_NO').format(testDate);

      // Assert
      expect(formatted, contains('10'));
      expect(formatted, contains('45'));
    });

    test('date formatter handles single-digit day and month', () {
      // Arrange
      final testDate = DateTime(2025, 1, 5, 8, 30);

      // Act
      final formatted = DateFormat.yMd('nb_NO').format(testDate);

      // Assert
      expect(formatted, contains('5'));
      expect(formatted, contains('1'));
      expect(formatted, contains('2025'));
    });

    test('time formatter handles midnight', () {
      // Arrange
      final testDate = DateTime(2025, 9, 28, 0, 0);

      // Act
      final formatted = DateFormat.Hm('nb_NO').format(testDate);

      // Assert
      // Midnight should format as 00:00
      expect(formatted, '00:00');
    });

    test('time formatter handles late evening', () {
      // Arrange
      final testDate = DateTime(2025, 9, 28, 23, 59);

      // Act
      final formatted = DateFormat.Hm('nb_NO').format(testDate);

      // Assert
      expect(formatted, contains('23'));
      expect(formatted, contains('59'));
    });

    test('formatters work with different languages - English', () {
      // Arrange
      final testDate = DateTime(2025, 9, 28, 10, 45);

      // Act
      final dateFormatted = DateFormat.yMd('en_US').format(testDate);
      final timeFormatted = DateFormat.Hm('en_US').format(testDate);

      // Assert
      expect(dateFormatted, isNotEmpty);
      expect(timeFormatted, '10:45');
    });

    test('formatters work with different languages - Swedish', () {
      // Arrange
      final testDate = DateTime(2025, 9, 28, 10, 45);

      // Act
      final dateFormatted = DateFormat.yMd('sv_SE').format(testDate);
      final timeFormatted = DateFormat.Hm('sv_SE').format(testDate);

      // Assert
      expect(dateFormatted, isNotEmpty);
      expect(timeFormatted, '10:45');
    });

    test('formatters work with different languages - Danish', () {
      // Arrange
      final testDate = DateTime(2025, 9, 28, 10, 45);

      // Act
      final dateFormatted = DateFormat.yMd('da_DK').format(testDate);
      final timeFormatted = DateFormat.Hm('da_DK').format(testDate);

      // Assert
      expect(dateFormatted, isNotEmpty);
      expect(timeFormatted, isNotEmpty);
      expect(timeFormatted, contains('10'));
      expect(timeFormatted, contains('45'));
    });

    test('now() datetime formats correctly', () {
      // Arrange & Act
      final now = DateTime.now();
      final dateFormatted = DateFormat.yMd('nb_NO').format(now);
      final timeFormatted = DateFormat.Hm('nb_NO').format(now);

      // Assert
      expect(dateFormatted, isNotEmpty);
      expect(timeFormatted, isNotEmpty);
      expect(timeFormatted, contains(':'));
    });

    test('formatted date is consistent across calls', () {
      // Arrange
      final testDate = DateTime(2025, 9, 28, 10, 45);

      // Act
      final formatted1 = DateFormat.yMd('nb_NO').format(testDate);
      final formatted2 = DateFormat.yMd('nb_NO').format(testDate);

      // Assert
      expect(formatted1, equals(formatted2));
    });

    test('formatted time is consistent across calls', () {
      // Arrange
      final testDate = DateTime(2025, 9, 28, 10, 45);

      // Act
      final formatted1 = DateFormat.Hm('nb_NO').format(testDate);
      final formatted2 = DateFormat.Hm('nb_NO').format(testDate);

      // Assert
      expect(formatted1, equals(formatted2));
    });
  });

  group('Session List Date/Time Display', () {
    test('session list displays date in dd.MM.yyyy HH:mm format', () {
      // Arrange
      final sessionDate = DateTime(2025, 9, 28, 10, 45);

      // Act
      final formatted = DateFormat('dd.MM.yyyy HH:mm').format(sessionDate);

      // Assert
      expect(formatted, equals('28.09.2025 10:45'));
    });

    test('session list display with single-digit day and month', () {
      // Arrange
      final sessionDate = DateTime(2025, 1, 5, 8, 30);

      // Act
      final formatted = DateFormat('dd.MM.yyyy HH:mm').format(sessionDate);

      // Assert
      expect(formatted, equals('05.01.2025 08:30'));
    });

    test('session list display with midnight', () {
      // Arrange
      final sessionDate = DateTime(2025, 9, 28, 0, 0);

      // Act
      final formatted = DateFormat('dd.MM.yyyy HH:mm').format(sessionDate);

      // Assert
      expect(formatted, equals('28.09.2025 00:00'));
    });

    test('session list display with late evening', () {
      // Arrange
      final sessionDate = DateTime(2025, 9, 28, 23, 59);

      // Act
      final formatted = DateFormat('dd.MM.yyyy HH:mm').format(sessionDate);

      // Assert
      expect(formatted, equals('28.09.2025 23:59'));
    });

    test('multiple sessions format consistently', () {
      // Arrange
      final sessions = [
        DateTime(2025, 9, 28, 10, 45),
        DateTime(2025, 9, 27, 14, 30),
        DateTime(2025, 9, 26, 8, 15),
      ];

      // Act
      final formatted = sessions
          .map((date) => DateFormat('dd.MM.yyyy HH:mm').format(date))
          .toList();

      // Assert
      expect(formatted, [
        '28.09.2025 10:45',
        '27.09.2025 14:30',
        '26.09.2025 08:15',
      ]);
    });
  });
}
