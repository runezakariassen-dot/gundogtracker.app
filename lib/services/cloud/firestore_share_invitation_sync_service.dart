import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/hive_boxes.dart';
import '../../models/dog_membership.dart';
import '../../models/share_invitation.dart';

class FirestoreShareInvitationSyncService {
  FirestoreShareInvitationSyncService._();

  static final FirestoreShareInvitationSyncService instance =
      FirestoreShareInvitationSyncService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collection = 'shareInvites';

  Future<void> upsertInviteBestEffort(ShareInvitation invite) async {
    try {
      final user = _auth.currentUser;
      final uid = user?.uid.trim() ?? '';
      if (uid.isEmpty) {
        debugPrint(
          '[CLOUD][INVITE] skip upsert: missing auth uid inviteId=${invite.inviteId} dogKey=${invite.dogKey} recipientEmail=${invite.recipientEmail.trim().toLowerCase()}',
        );
        return;
      }

      await _firestore.collection(_collection).doc(invite.inviteId).set(
            _mapInviteToFirestore(invite, createdByAuthUid: uid),
            SetOptions(merge: true),
          );
      debugPrint(
        '[CLOUD][INVITE] upsert success inviteId=${invite.inviteId} dogKey=${invite.dogKey} recipientEmail=${invite.recipientEmail.trim().toLowerCase()}',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[CLOUD][INVITE] upsert failed inviteId=${invite.inviteId} dogKey=${invite.dogKey} recipientEmail=${invite.recipientEmail.trim().toLowerCase()} error=$error',
      );
      debugPrint(stackTrace.toString());
    }
  }

  Future<int> pullPendingInvitesForCurrentUserIntoLocalBox() async {
    String? email;
    try {
      email = _auth.currentUser?.email?.trim().toLowerCase();
      if (email == null || email.isEmpty) {
        debugPrint('[CLOUD][INVITE] skip pull: missing auth email');
        return 0;
      }

      final snapshot = await _firestore
          .collection(_collection)
          .where('recipientEmail', isEqualTo: email)
          .where('status', isEqualTo: Status.pending.name)
          .get();

      final box = shareInvitesBox();
      var upserted = 0;
      for (final doc in snapshot.docs) {
        final invite = _mapFirestoreToInvite(doc.id, doc.data());
        await box.put(invite.inviteId, invite);
        upserted += 1;
      }

      debugPrint(
        '[CLOUD][INVITE] pull complete email=$email upserted=$upserted',
      );
      return upserted;
    } catch (error, stackTrace) {
      debugPrint('[CLOUD][INVITE] pull failed email=$email error=$error');
      debugPrint(stackTrace.toString());
      return 0;
    }
  }

  Map<String, dynamic> _mapInviteToFirestore(
    ShareInvitation invite, {
    required String createdByAuthUid,
  }) {
    return <String, dynamic>{
      'inviteId': invite.inviteId,
      'dogKey': invite.dogKey,
      'cloudDogId': invite.cloudDogId,
      'role': invite.role.name,
      'token': invite.token,
      'createdAt': Timestamp.fromDate(invite.createdAt.toUtc()),
      'expiresAt': Timestamp.fromDate(invite.expiresAt.toUtc()),
      'status': invite.status.name,
      'recipientEmail': invite.recipientEmail.trim().toLowerCase(),
      'recipientUserId': invite.recipientUserId,
      'createdByUserId': invite.createdByUserId,
      'createdByAuthUid': createdByAuthUid,
      'senderDisplayName': invite.senderDisplayName,
      'senderEmail': invite.senderEmail?.trim().toLowerCase(),
      'dogName': invite.dogName,
      'updatedAt': FieldValue.serverTimestamp(),
    }..removeWhere((key, value) => value == null);
  }

  ShareInvitation _mapFirestoreToInvite(
    String docId,
    Map<String, dynamic> data,
  ) {
    return ShareInvitation(
      inviteId: _readString(data['inviteId']) ?? docId,
      dogKey: _readString(data['dogKey']) ?? '',
      role: _parseRole(_readString(data['role'])),
      token: _readString(data['token']) ?? '',
      createdAt: _readDateTime(data['createdAt']) ?? DateTime.now(),
      expiresAt: _readDateTime(data['expiresAt']) ?? DateTime.now(),
      status: _parseStatus(_readString(data['status'])),
      recipientEmail: (_readString(data['recipientEmail']) ?? '').toLowerCase(),
      recipientUserId: _readString(data['recipientUserId']),
      createdByUserId: _readString(data['createdByUserId']) ?? '',
      cloudDogId: _readString(data['cloudDogId']),
      senderDisplayName: _readString(data['senderDisplayName']),
      senderEmail: _readString(data['senderEmail'])?.toLowerCase(),
      dogName: _readString(data['dogName']),
    );
  }

  String? _readString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  DateTime? _readDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Role _parseRole(String? value) {
    if (value == null || value.isEmpty) {
      return Role.viewer;
    }
    return Role.values.firstWhere(
      (role) => role.name == value,
      orElse: () => Role.viewer,
    );
  }

  Status _parseStatus(String? value) {
    if (value == null || value.isEmpty) {
      return Status.pending;
    }
    return Status.values.firstWhere(
      (status) => status.name == value,
      orElse: () => Status.pending,
    );
  }
}
