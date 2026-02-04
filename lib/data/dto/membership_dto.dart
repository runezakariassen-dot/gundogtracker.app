import '../../models/dog_membership.dart';

Map<String, dynamic> membershipToJson(DogMembership membership) {
  return {
    'dogKey': membership.dogKey,
    'userId': membership.userId,
    'role': membership.role.name,
    'status': membership.status.name,
    'addedAt': membership.addedAt.toIso8601String(),
    'addedByUserId': membership.addedByUserId,
  };
}

DogMembership membershipFromJson(Map<String, dynamic> json) {
  final role = _parseRole(json['role'] as String?);
  final status = _parseStatus(json['status'] as String?);
  return DogMembership(
    dogKey: json['dogKey'] as String? ?? '',
    userId: json['userId'] as String? ?? '',
    role: role,
    status: status,
    addedAt: _parseDate(json['addedAt']) ?? DateTime.now(),
    addedByUserId: json['addedByUserId'] as String? ?? '',
  );
}

Role _parseRole(String? value) {
  return Role.values.firstWhere(
    (r) => r.name == value,
    orElse: () => Role.viewer,
  );
}

Status _parseStatus(String? value) {
  return Status.values.firstWhere(
    (s) => s.name == value,
    orElse: () => Status.pending,
  );
}

DateTime? _parseDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
