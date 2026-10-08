import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/dog_heat_cycle_log.dart';
import 'heat_cycle_firestore_mapper.dart';

class FirestoreHeatCycleSyncService {
  FirestoreHeatCycleSyncService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static final FirestoreHeatCycleSyncService instance =
      FirestoreHeatCycleSyncService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> upsertHeatCycle({
    required DogHeatCycleLog entry,
    required String cloudDogId,
  }) async {
    final normalizedCloudDogId = cloudDogId.trim();
    if (normalizedCloudDogId.isEmpty) {
      throw StateError('Missing cloud dog id for heat cycle sync.');
    }

    final heatCycleId = entry.id?.trim();
    if (heatCycleId == null || heatCycleId.isEmpty) {
      throw StateError('Missing heat cycle id for sync.');
    }

    final reference = _firestore
        .collection('dogs')
        .doc(normalizedCloudDogId)
        .collection('heatCycles')
        .doc(heatCycleId);

    final incomingCreatedBy = entry.createdByUserId ?? _auth.currentUser?.uid;
    if (incomingCreatedBy == null || incomingCreatedBy.trim().isEmpty) {
      throw StateError('Missing creator user id for heat cycle sync.');
    }

    final incomingPayload = heatCycleToFirestore(
      entry: entry,
      cloudDogId: normalizedCloudDogId,
      createdByUserId: incomingCreatedBy,
    );

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final existing = snapshot.data();
      final decision = heatCycleCloudWriteDecision(
        existingData: existing,
        incomingUpdatedAt: entry.updatedAt,
      );
      if (decision != HeatCycleCloudWriteDecision.written) return;

      final payload = heatCycleTransactionPayload(
        incomingPayload: incomingPayload,
        existingData: existing,
      );
      transaction.set(reference, payload);
    });
  }

  Future<List<DogHeatCycleLog>> fetchHeatCyclesForDog({
    required String cloudDogId,
    required String localDogId,
    DateTime? updatedAfter,
  }) async {
    Query<Map<String, dynamic>> query =
        _firestore.collection('dogs').doc(cloudDogId).collection('heatCycles');

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
        '[SYNC][DELTA] heat cycle full fetch fallback: ${error.code}',
      );
      snapshot = await _firestore
          .collection('dogs')
          .doc(cloudDogId)
          .collection('heatCycles')
          .get();
    }

    final entries = <DogHeatCycleLog>[];
    for (final document in snapshot.docs) {
      try {
        entries.add(
          heatCycleFromFirestore(
            data: document.data(),
            documentId: document.id,
            localDogId: localDogId,
          ),
        );
      } on FormatException catch (error) {
        debugPrint(
          '[SYNC][HEAT] skipped corrupt document ${document.id}: $error',
        );
      }
    }
    return entries;
  }
}

enum HeatCycleCloudWriteDecision { written, alreadyCurrent, cloudNewer }

HeatCycleCloudWriteDecision heatCycleCloudWriteDecision({
  required Map<String, dynamic>? existingData,
  required DateTime incomingUpdatedAt,
}) {
  if (existingData == null) return HeatCycleCloudWriteDecision.written;
  final existingUpdatedAt = _dateTime(existingData['updatedAt']);
  if (existingUpdatedAt == null) return HeatCycleCloudWriteDecision.written;

  final comparison = incomingUpdatedAt.toUtc().compareTo(existingUpdatedAt);
  if (comparison > 0) return HeatCycleCloudWriteDecision.written;
  if (comparison == 0) {
    return HeatCycleCloudWriteDecision.alreadyCurrent;
  }
  return HeatCycleCloudWriteDecision.cloudNewer;
}

Map<String, dynamic> heatCycleTransactionPayload({
  required Map<String, dynamic> incomingPayload,
  required Map<String, dynamic>? existingData,
}) {
  final payload = Map<String, dynamic>.from(incomingPayload);
  if (existingData == null) return payload;
  payload['createdAt'] = existingData['createdAt'];
  payload['createdByUserId'] =
      existingData['createdByUserId'] ?? existingData['createdBy'];
  payload['cloudDogId'] = existingData['cloudDogId'];
  return payload;
}

DateTime? _dateTime(dynamic raw) {
  if (raw is Timestamp) return raw.toDate().toUtc();
  if (raw is DateTime) return raw.toUtc();
  if (raw is String) return DateTime.tryParse(raw)?.toUtc();
  return null;
}
