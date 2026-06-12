import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/domain/settings/birthday_greeting.dart';

void main() {
  test('no birth date means no greeting', () {
    final shouldShow = BirthdayGreeting.shouldShow(
      birthDate: null,
      today: DateTime(2026, 4, 28),
      lastShownDate: null,
    );

    expect(shouldShow, isFalse);
  });

  test('birthday today triggers greeting regardless of birth year', () {
    final shouldShow = BirthdayGreeting.shouldShow(
      birthDate: DateTime(1989, 4, 28),
      today: DateTime(2026, 4, 28),
      lastShownDate: null,
    );

    expect(shouldShow, isTrue);
  });

  test('wrong date means no greeting', () {
    final shouldShow = BirthdayGreeting.shouldShow(
      birthDate: DateTime(1989, 7, 14),
      today: DateTime(2026, 4, 28),
      lastShownDate: null,
    );

    expect(shouldShow, isFalse);
  });

  test('greeting is shown only once on the same day', () {
    final shouldShow = BirthdayGreeting.shouldShow(
      birthDate: DateTime(1989, 4, 28),
      today: DateTime(2026, 4, 28),
      lastShownDate: DateTime(2026, 4, 28),
    );

    expect(shouldShow, isFalse);
  });

  test('message uses name when set', () {
    final message = BirthdayGreeting.resolveMessage(
      name: 'Rune',
      dogNames: const [],
      andWord: 'og',
      genericMessage: 'Gratulerer med dagen 🎉',
      namedMessage: (name) => 'Gratulerer med dagen, $name! 🎉',
      dogsGenericMessage: (dogs) => 'Gratulerer med dagen! Hilsen $dogs 🎉',
      dogsNamedMessage: (name, dogs) =>
          'Gratulerer med dagen, $name! Hilsen $dogs 🎉',
    );

    expect(message, 'Gratulerer med dagen, Rune! 🎉');
  });

  test('dog names are included when dogs exist', () {
    final message = BirthdayGreeting.resolveMessage(
      name: 'Rune',
      dogNames: const ['Bella', 'Max', 'Luna'],
      andWord: 'og',
      genericMessage: 'Gratulerer med dagen 🎉',
      namedMessage: (name) => 'Gratulerer med dagen, $name! 🎉',
      dogsGenericMessage: (dogs) => 'Gratulerer med dagen! Hilsen $dogs 🎉',
      dogsNamedMessage: (name, dogs) =>
          'Gratulerer med dagen, $name! Hilsen $dogs 🎉',
    );

    expect(
      message,
      'Gratulerer med dagen, Rune! Hilsen Bella, Max og Luna 🎉',
    );
  });

  test('generic greeting works without dogs', () {
    final message = BirthdayGreeting.resolveMessage(
      name: null,
      dogNames: const [],
      andWord: 'og',
      genericMessage: 'Gratulerer med dagen 🎉',
      namedMessage: (name) => 'Gratulerer med dagen, $name! 🎉',
      dogsGenericMessage: (dogs) => 'Gratulerer med dagen! Hilsen $dogs 🎉',
      dogsNamedMessage: (name, dogs) =>
          'Gratulerer med dagen, $name! Hilsen $dogs 🎉',
    );

    expect(message, 'Gratulerer med dagen 🎉');
  });
}
