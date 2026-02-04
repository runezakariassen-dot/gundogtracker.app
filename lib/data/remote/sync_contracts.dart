class RemoteDogDto {
  RemoteDogDto({
    required this.id,
    required this.dogKey,
    required this.name,
    required this.regNrDisplay,
    required this.ownerUserId,
    required this.updatedAt,
    this.imagePath,
    this.birthDate,
    this.pedigreeUrl,
    this.breed,
  });

  final String id;
  final String dogKey;
  final String name;
  final String regNrDisplay;
  final String? ownerUserId;
  final DateTime updatedAt;
  final String? imagePath;
  final DateTime? birthDate;
  final String? pedigreeUrl;
  final String? breed;

  factory RemoteDogDto.fromJson(Map<String, dynamic> row) {
    return RemoteDogDto(
      id: _requireString(row, 'id'),
      dogKey: _requireString(row, 'dog_key'),
      name: _requireString(row, 'name'),
      regNrDisplay: _requireString(row, 'reg_nr_display'),
      ownerUserId: _readString(row, 'owner_user_id'),
      updatedAt: _requireDate(row, 'updated_at'),
      imagePath: _readString(row, 'image_path'),
      birthDate: _readDate(row, 'birth_date'),
      pedigreeUrl: _readString(row, 'pedigree_url'),
      breed: _readString(row, 'breed'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dog_key': dogKey,
      'name': name,
      'reg_nr_display': regNrDisplay,
      'owner_user_id': ownerUserId,
      'updated_at': updatedAt.toIso8601String(),
      'image_path': imagePath,
      'birth_date': birthDate?.toIso8601String(),
      'pedigree_url': pedigreeUrl,
      'breed': breed,
    };
  }
}

class RemoteDogMembershipDto {
  RemoteDogMembershipDto({
    required this.id,
    required this.dogId,
    required this.userId,
    required this.role,
    required this.status,
    required this.updatedAt,
  });

  final String id;
  final String dogId;
  final String userId;
  final String role;
  final String status;
  final DateTime updatedAt;

  factory RemoteDogMembershipDto.fromJson(Map<String, dynamic> row) {
    return RemoteDogMembershipDto(
      id: _requireString(row, 'id'),
      dogId: _requireString(row, 'dog_id'),
      userId: _requireString(row, 'user_id'),
      role: _requireString(row, 'role'),
      status: _requireString(row, 'status'),
      updatedAt: _requireDate(row, 'updated_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dog_id': dogId,
      'user_id': userId,
      'role': role,
      'status': status,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class RemoteDogWithRole {
  RemoteDogWithRole({
    required this.dog,
    required this.role,
  });

  final RemoteDogDto dog;
  final String role;

  factory RemoteDogWithRole.fromJson(Map<String, dynamic> row) {
    final dogRow = _requireMap(row, 'dog');
    return RemoteDogWithRole(
      dog: RemoteDogDto.fromJson(dogRow),
      role: _requireString(row, 'role'),
    );
  }
}

class RemoteDelta {
  RemoteDelta({
    required this.dogs,
    required this.memberships,
    this.serverTime,
  });

  final List<RemoteDogDto> dogs;
  final List<RemoteDogMembershipDto> memberships;
  final DateTime? serverTime;

  factory RemoteDelta.fromJson(Map<String, dynamic> row) {
    return RemoteDelta(
      dogs: _readList(row, 'dogs', RemoteDogDto.fromJson),
      memberships:
          _readList(row, 'memberships', RemoteDogMembershipDto.fromJson),
      serverTime: _readDate(row, 'server_time'),
    );
  }
}

class PullDogDeltaResponse {
  PullDogDeltaResponse({
    required this.serverTime,
    required this.dogId,
    required this.since,
    required this.dogs,
    required this.memberships,
  });

  final DateTime serverTime;
  final String dogId;
  final DateTime since;
  final List<RemoteDogDto> dogs;
  final List<RemoteDogMembershipDto> memberships;

  factory PullDogDeltaResponse.fromJson(Map<String, dynamic> row) {
    return PullDogDeltaResponse(
      serverTime: _requireDate(row, 'server_time'),
      dogId: _requireString(row, 'dog_id'),
      since: _requireDate(row, 'since'),
      dogs: _readList(row, 'dogs', RemoteDogDto.fromJson),
      memberships:
          _readList(row, 'memberships', RemoteDogMembershipDto.fromJson),
    );
  }
}

List<T> _readList<T>(
  Map<String, dynamic> row,
  String key,
  T Function(Map<String, dynamic>) mapper,
) {
  final value = row[key];
  if (value == null) {
    return <T>[];
  }
  if (value is List) {
    return value.map((item) {
      if (item is Map<String, dynamic>) {
        return mapper(item);
      }
      throw FormatException('Invalid list item for "$key".');
    }).toList();
  }
  throw FormatException('Invalid list for "$key".');
}

String _requireString(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Missing or invalid string for "$key".');
}

String? _readString(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  throw FormatException('Invalid string for "$key".');
}

Map<String, dynamic> _requireMap(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value is Map<String, dynamic>) {
    return value;
  }
  throw FormatException('Missing or invalid map for "$key".');
}

Map<String, dynamic>? _readMap(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value == null) {
    return null;
  }
  if (value is Map<String, dynamic>) {
    return value;
  }
  throw FormatException('Invalid map for "$key".');
}

DateTime _requireDate(Map<String, dynamic> row, String key) {
  final value = row[key];
  final parsed = _parseDate(value);
  if (parsed == null) {
    throw FormatException('Missing or invalid date for "$key".');
  }
  return parsed;
}

DateTime? _readDate(Map<String, dynamic> row, String key) {
  return _parseDate(row[key]);
}

DateTime? _parseDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  throw const FormatException('Invalid date value.');
}

class RemoteChange {
  RemoteChange({
    required this.table,
    required this.op,
    required this.clientOpId,
    this.row,
    this.pk,
  });

  final String table;
  final String op;
  final String clientOpId;
  final Map<String, dynamic>? row;
  final Map<String, dynamic>? pk;

  factory RemoteChange.fromJson(Map<String, dynamic> row) {
    final table = _requireString(row, 'table');
    final op = _requireString(row, 'op');
    if (!_allowedTables.contains(table)) {
      throw FormatException('Invalid table "$table".');
    }
    if (!_allowedOps.contains(op)) {
      throw FormatException('Invalid op "$op".');
    }
    final clientOpId = _requireString(row, 'client_op_id');
    final payload = _readMap(row, 'row');
    final pk = _readMap(row, 'pk');
    if (op == 'upsert' && payload == null) {
      throw const FormatException('Missing row for upsert.');
    }
    if (op == 'delete' && pk == null) {
      throw const FormatException('Missing pk for delete.');
    }
    return RemoteChange(
      table: table,
      op: op,
      clientOpId: clientOpId,
      row: payload,
      pk: pk,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'table': table,
      'op': op,
      'client_op_id': clientOpId,
      if (row != null) 'row': row,
      if (pk != null) 'pk': pk,
    };
  }
}

const List<String> _allowedTables = <String>[
  'dogs',
  'dog_memberships',
  'invites',
  'ownership_transfers',
];

const List<String> _allowedOps = <String>['upsert', 'delete'];
