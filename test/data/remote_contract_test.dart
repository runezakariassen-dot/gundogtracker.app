import 'package:flutter_test/flutter_test.dart';

import 'package:jakthund_app/data/remote/sync_contracts.dart';

void main() {
  test('RemoteDelta.fromJson parses dogs and memberships', () {
    final payload = {
      'server_time': '2024-01-01T10:00:00Z',
      'dogs': [
        {
          'id': 'dog-1',
          'dog_key': 'NO123-45',
          'name': 'Birk',
          'reg_nr_display': 'NO123/45',
          'owner_user_id': 'owner',
          'updated_at': '2024-01-01T10:00:00Z',
        }
      ],
      'memberships': [
        {
          'id': 'mem-1',
          'dog_id': 'dog-1',
          'user_id': 'user-1',
          'role': 'viewer',
          'status': 'active',
          'updated_at': '2024-01-01T10:00:00Z',
        }
      ],
    };

    final delta = RemoteDelta.fromJson(payload);
    expect(delta.serverTime, DateTime.parse('2024-01-01T10:00:00Z'));
    expect(delta.dogs, hasLength(1));
    expect(delta.memberships, hasLength(1));
  });

  test('RemoteDelta.fromJson throws on invalid list item', () {
    final payload = {
      'dogs': ['not-a-map'],
    };

    expect(
      () => RemoteDelta.fromJson(payload),
      throwsA(isA<FormatException>()),
    );
  });

  test('RemoteChange.fromJson parses upsert', () {
    final payload = {
      'table': 'dogs',
      'op': 'upsert',
      'client_op_id': 'op-1',
      'row': {
        'id': 'dog-1',
      },
    };

    final change = RemoteChange.fromJson(payload);
    expect(change.table, 'dogs');
    expect(change.op, 'upsert');
    expect(change.row, isNotNull);
  });

  test('RemoteChange.fromJson rejects missing pk for delete', () {
    final payload = {
      'table': 'dogs',
      'op': 'delete',
      'client_op_id': 'op-2',
    };

    expect(
      () => RemoteChange.fromJson(payload),
      throwsA(isA<FormatException>()),
    );
  });

  test('PullDogDeltaResponse.fromJson parses response shape', () {
    final payload = {
      'server_time': '2024-01-02T10:00:00Z',
      'dog_id': 'dog-1',
      'since': '2024-01-01T10:00:00Z',
      'dogs': [
        {
          'id': 'dog-1',
          'dog_key': 'NO123-45',
          'name': 'Birk',
          'reg_nr_display': 'NO123/45',
          'owner_user_id': 'owner',
          'updated_at': '2024-01-02T09:00:00Z',
        }
      ],
      'memberships': [
        {
          'id': 'mem-1',
          'dog_id': 'dog-1',
          'user_id': 'user-1',
          'role': 'viewer',
          'status': 'active',
          'updated_at': '2024-01-02T09:00:00Z',
        }
      ],
    };

    final response = PullDogDeltaResponse.fromJson(payload);
    expect(response.dogId, 'dog-1');
    expect(response.dogs, hasLength(1));
    expect(response.memberships, hasLength(1));
  });
}
