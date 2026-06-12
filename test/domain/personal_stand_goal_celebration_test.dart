import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/domain/settings/personal_stand_goal_celebration.dart';

void main() {
  test('celebration message uses name when available', () {
    final message = PersonalStandGoalCelebration.resolveMessage(
      name: 'Rune',
      genericMessage: 'Gratulerer! Du har nådd ditt mål 🎉',
      namedMessage: (name) => 'Gratulerer $name! Du har nådd ditt mål 🎉',
    );

    expect(message, 'Gratulerer Rune! Du har nådd ditt mål 🎉');
  });

  test('celebration message falls back when name is missing', () {
    final message = PersonalStandGoalCelebration.resolveMessage(
      name: '   ',
      genericMessage: 'Gratulerer! Du har nådd ditt mål 🎉',
      namedMessage: (name) => 'Gratulerer $name! Du har nådd ditt mål 🎉',
    );

    expect(message, 'Gratulerer! Du har nådd ditt mål 🎉');
  });
}
