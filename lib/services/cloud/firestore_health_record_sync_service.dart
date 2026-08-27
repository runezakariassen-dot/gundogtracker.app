import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/health_record.dart';
import 'health_record_firestore_mapper.dart';

class FirestoreHealthRecordSyncService {
  FirestoreHealthRecordSyncService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static final FirestoreHealthRecordSyncService instance =
      FirestoreHealthRecordSyncService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> upsertHealthRecord({
    required HealthRecord record,
    required String cloudDogId,
  }) async {
    final normalizedCloudDogId = cloudDogId.trim();
    if (normalizedCloudDogId.isEmpty) {
      throw StateError('Missing cloud dog id for health record sync.');
    }

    final reference = _firestore
        .collection('dogs')
        .doc(normalizedCloudDogId)
        .collection('healthRecords')
        .doc(record.id);
    final incomingCreatedBy = record.createdByUserId ?? _auth.currentUser?.uid;
    if (incomingCreatedBy == null || incomingCreatedBy.trim().isEmpty) {
      throw StateError('Missing creator user id for health record sync.');
    }
    final incomingPayload = healthRecordToFirestore(
      record: record,
      cloudDogId: normalizedCloudDogId,
      createdByUserId: incomingCreatedBy,
    );

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final existing = snapshot.data();
      final decision = healthRecordCloudWriteDecision(
        existingData: existing,
        incomingUpdatedAt: record.updatedAt,
      );
      if (decision != HealthRecordCloudWriteDecision.written) return;

      final payload = healthRecordTransactionPayload(
        incomingPayload: incomingPayload,
        existingData: existing,
      );
      transaction.set(reference, payload);
    });
  }

  Future<List<HealthRecord>> fetchHealthRecordsForDog({
    required String cloudDogId,
    required String localDogId,
    String? localDogKey,
    DateTime? updatedAfter,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('dogs')
        .doc(cloudDogId)
        .collection('healthRecords');
    if (updatedAfter != null) {
      query = query.where(
        'updatedAt',
        isGreaterThan: Timestamp.fromDate(updatedAfter.toUtc()),
      );
    }

    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await query.get();
    } on FirebaseException catch (error) {
      if (updatedAfter == null) rethrow;
      debugPrint(
        '[SYNC][DELTA] health record full fetch fallback: ${error.code}',
      );
      snapshot = await _firestore
          .collection('dogs')
          .doc(cloudDogId)
          .collection('healthRecords')
          .get();
    }

    final records = <HealthRecord>[];
    for (final document in snapshot.docs) {
      try {
        records.add(
          healthRecordFromFirestore(
            data: document.data(),
            documentId: document.id,
            localDogId: localDogId,
            localDogKey: localDogKey,
          ),
        );
      } on FormatException catch (error) {
        debugPrint(
          '[SYNC][HEALTH] skipped corrupt document ${document.id}: $error',
        );
      }
    }
    return records;
  }
}

enum HealthRecordCloudWriteDecision { written, alreadyCurrent, cloudNewer }

HealthRecordCloudWriteDecision healthRecordCloudWriteDecision({
  required Map<String, dynamic>? existingData,
  required DateTime incomingUpdatedAt,
}) {
  if (existingData == null) return HealthRecordCloudWriteDecision.written;
  final existingUpdatedAt = _dateTime(existingData['updatedAt']);
  if (existingUpdatedAt == null) return HealthRecordCloudWriteDecision.written;
  final comparison = incomingUpdatedAt.toUtc().compareTo(existingUpdatedAt);
  if (comparison > 0) return HealthRecordCloudWriteDecision.written;
  if (comparison == 0) {
    return HealthRecordCloudWriteDecision.alreadyCurrent;
  }
  return HealthRecordCloudWriteDecision.cloudNewer;
}

Map<String, dynamic> healthRecordTransactionPayload({
  required Map<String, dynamic> incomingPayload,
  required Map<String, dynamic>? existingData,
}) {
  final payload = Map<String, dynamic>.from(incomingPayload);
  if (existingData == null) return payload;
  payload['createdAt'] = existingData['createdAt'];
  payload['createdByUserId'] =
      existingData['createdByUserId'] ?? existingData['createdBy'];
  payload['dogKey'] = existingData['dogKey'];
  return payload;
}

DateTime? _dateTime(dynamic raw) {
  if (raw is Timestamp) return raw.toDate().toUtc();
  if (raw is DateTime) return raw.toUtc();
  if (raw is String) return DateTime.tryParse(raw)?.toUtc();
  return null;
}
