import '../../models/dog_membership.dart';
import '../../models/share_invitation.dart';

Map<String, dynamic> shareInvitationToJson(ShareInvitation invite) {
  return {
    'inviteId': invite.inviteId,
    'dogKey': invite.dogKey,
    'role': invite.role.name,
    'token': invite.token,
    'createdAt': invite.createdAt.toIso8601String(),
    'expiresAt': invite.expiresAt.toIso8601String(),
    'status': invite.status.name,
    'recipientEmail': invite.recipientEmail,
    'recipientUserId': invite.recipientUserId,
    'createdByUserId': invite.createdByUserId,
    'cloudDogId': invite.cloudDogId,
    'senderDisplayName': invite.senderDisplayName,
    'senderEmail': invite.senderEmail,
    'dogName': invite.dogName,
  };
}

ShareInvitation shareInvitationFromJson(Map<String, dynamic> json) {
  return ShareInvitation(
    inviteId: json['inviteId'] as String? ?? '',
    dogKey: json['dogKey'] as String? ?? '',
    role: _parseRole(json['role'] as String?),
    token: json['token'] as String? ?? '',
    createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
    expiresAt: _parseDate(json['expiresAt']) ?? DateTime.now(),
    status: _parseStatus(json['status'] as String?),
    recipientEmail: _normalizeEmail(json['recipientEmail'] as String?),
    recipientUserId: json['recipientUserId'] as String?,
    createdByUserId: json['createdByUserId'] as String? ?? '',
    cloudDogId: json['cloudDogId'] as String?,
    senderDisplayName: json['senderDisplayName'] as String?,
    senderEmail: _normalizeEmail(json['senderEmail'] as String?),
    dogName: json['dogName'] as String?,
  );
}

Role _parseRole(String? value) {
  if (value == null || value.isEmpty) {
    return Role.viewer;
  }
  final normalized = value.toLowerCase();
  if (normalized == 'reader' || normalized == 'leser') {
    return Role.viewer;
  }
  return Role.values.firstWhere(
    (r) => r.name == normalized,
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

String _normalizeEmail(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.toLowerCase();
}
