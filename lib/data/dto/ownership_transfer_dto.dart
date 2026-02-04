import '../../models/dog_membership.dart';
import '../../models/ownership_transfer.dart';

Map<String, dynamic> ownershipTransferToJson(OwnershipTransfer transfer) {
  return {
    'transferId': transfer.transferId,
    'dogKey': transfer.dogKey,
    'fromUserId': transfer.fromUserId,
    'toUserId': transfer.toUserId,
    'createdAt': transfer.createdAt.toIso8601String(),
    'expiresAt': transfer.expiresAt.toIso8601String(),
    'status': transfer.status.name,
  };
}

OwnershipTransfer ownershipTransferFromJson(Map<String, dynamic> json) {
  return OwnershipTransfer(
    transferId: json['transferId'] as String? ?? '',
    dogKey: json['dogKey'] as String? ?? '',
    fromUserId: json['fromUserId'] as String? ?? '',
    toUserId: json['toUserId'] as String? ?? '',
    status: _parseStatus(json['status'] as String?),
    createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
    expiresAt: _parseDate(json['expiresAt']) ?? DateTime.now(),
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
