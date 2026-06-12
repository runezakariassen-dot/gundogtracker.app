import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/models/dog.dart';

void main() {
  test('Dog retains title and copyWith overrides it', () {
    final dog = Dog(
      name: 'Fido',
      dogKey: 'dog-key',
      regNrDisplay: '123',
      title: 'NUCH',
    );

    expect(dog.title, 'NUCH');

    final updated = dog.copyWith(title: 'DKCH');
    expect(updated.title, 'DKCH');
  });

  test('toJson serializes title', () {
    final dog = Dog(
      name: 'Fido',
      dogKey: 'dog-key',
      regNrDisplay: '123',
      title: 'NUCH',
    );

    final json = dog.toJson();
    expect(json['title'], 'NUCH');
  });

  test('copyWith updates memorialStory', () {
    final dog = Dog(
      name: 'Fido',
      dogKey: 'dog-key',
      regNrDisplay: '123',
      memorialStory: 'Original story',
    );

    final updated = dog.copyWith(memorialStory: 'Updated story');
    expect(updated.memorialStory, 'Updated story');
  });

  test('toJson serializes memorialStory', () {
    final dog = Dog(
      name: 'Fido',
      dogKey: 'dog-key',
      regNrDisplay: '123',
      memorialStory: 'A long memory text',
    );

    final json = dog.toJson();
    expect(json['memorialStory'], 'A long memory text');
  });
}
