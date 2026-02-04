import 'package:flutter_test/flutter_test.dart';

import 'package:jakthund_app/data/remote/sync_contracts.dart';

void main() {
  test('RemoteDogDto.fromJson parses required fields', () {
    final row = {
      'id': 'dog-1',
      'dog_key': 'NO123-45',
      'name': 'Birk',
      'reg_nr_display': 'NO123/45',
      'owner_user_id': 'owner',
      'updated_at': '2024-01-01T10:00:00Z',
      'image_path': '/tmp/dog.png',
      'birth_date': '2020-05-01T00:00:00Z',
      'pedigree_url': 'https://example.com',
      'breed': 'Elghund',
    };

    final dto = RemoteDogDto.fromJson(row);
    expect(dto.id, 'dog-1');
    expect(dto.dogKey, 'NO123-45');
    expect(dto.name, 'Birk');
    expect(dto.regNrDisplay, 'NO123/45');
    expect(dto.ownerUserId, 'owner');
    expect(dto.updatedAt, DateTime.parse('2024-01-01T10:00:00Z'));
    expect(dto.birthDate, DateTime.parse('2020-05-01T00:00:00Z'));

    final encoded = dto.toJson();
    expect(encoded['dog_key'], 'NO123-45');
    expect(encoded['updated_at'], '2024-01-01T10:00:00.000Z');
  });

  test('RemoteDogMembershipDto.fromJson parses timestamptz fields', () {
    final row = {
      'id': 'mem-1',
      'dog_id': 'dog-1',
      'user_id': 'user-1',
      'role': 'viewer',
      'status': 'active',
      'updated_at': DateTime.parse('2024-01-01T10:00:00Z'),
    };

    final dto = RemoteDogMembershipDto.fromJson(row);
    expect(dto.id, 'mem-1');
    expect(dto.dogId, 'dog-1');
    expect(dto.userId, 'user-1');
    expect(dto.role, 'viewer');
    expect(dto.status, 'active');
    expect(dto.updatedAt, DateTime.parse('2024-01-01T10:00:00Z'));
  });

  test('Missing required field throws FormatException', () {
    final row = {
      'id': 'membership-1',
      'dog_id': 'dog-1',
      'user_id': 'user-1',
      'role': 'editor',
      'updated_at': '2024-01-01T10:00:00Z',
    };

    expect(
      () => RemoteDogMembershipDto.fromJson(row),
      throwsA(isA<FormatException>()),
    );
  });
}
