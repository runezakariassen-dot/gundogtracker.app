import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/hunt_event.dart';

class FirestoreHuntEventSyncService {
  FirestoreHuntEventSyncService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final instance = FirestoreHuntEventSyncService();
  final FirebaseFirestore _firestore;

  static String documentPath(String cloudDogId, String eventId) =>
      'dogs/$cloudDogId/events/$eventId';

  Future<void> upsert({
    required HuntEvent event,
    required String cloudDogId,
  }) async {
    final ref = _firestore
        .collection('dogs')
        .doc(cloudDogId)
        .collection('events')
        .doc(event.id);
    await _firestore.runTransaction((transaction) async {
      final existing = (await transaction.get(ref)).data();
      final existingUpdatedAt = _dateTime(existing?['updatedAt']);
      if (existingUpdatedAt != null &&
          !event.updatedAt.toUtc().isAfter(existingUpdatedAt)) {
        return;
      }
      final payload = toFirestore(event, cloudDogId: cloudDogId);
      if (existing != null) {
        payload['createdAt'] = existing['createdAt'];
        payload['createdByUserId'] = existing['createdByUserId'];
      }
      transaction.set(ref, payload);
    });
  }

  Future<List<HuntEvent>> fetchForDog({
    required String cloudDogId,
    required String localDogId,
    String? localDogKey,
    DateTime? updatedAfter,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('dogs')
        .doc(cloudDogId)
        .collection('events');
    if (updatedAfter != null) {
      query = query.where(
        'updatedAt',
        isGreaterThan: Timestamp.fromDate(updatedAfter.toUtc()),
      );
    }
    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await query.get();
    } on FirebaseException {
      if (updatedAfter == null) rethrow;
      snapshot = await _firestore
          .collection('dogs')
          .doc(cloudDogId)
          .collection('events')
          .get();
    }
    final events = <HuntEvent>[];
    for (final doc in snapshot.docs) {
      try {
        events.add(
          fromFirestore(
            doc.data(),
            eventId: doc.id,
            localDogId: localDogId,
            localDogKey: localDogKey,
          ),
        );
      } on FormatException catch (error, stackTrace) {
        debugPrint(
          '[SYNC][HUNT_EVENT] skipping invalid cloud event ${doc.id}: '
          '$error\n$stackTrace',
        );
      }
    }
    return events;
  }

  static Map<String, dynamic> toFirestore(
    HuntEvent event, {
    required String cloudDogId,
  }) => <String, dynamic>{
    'eventId': event.id,
    'sessionId': event.sessionId,
    'dogId': cloudDogId,
    'type': event.typeValue,
    'occurredAt': Timestamp.fromDate(event.occurredAt.toUtc()),
    'sourceTrackId': event.sourceTrackId,
    'trackPointIndex': event.trackPointIndex,
    'latitude': event.latitude,
    'longitude': event.longitude,
    'birdSpecies': event.birdSpecies,
    'note': event.note,
    'source': event.sourceValue,
    'sourceWaypointName': event.sourceWaypointName,
    'sourceWaypointSymbol': event.sourceWaypointSymbol,
    'createdAt': Timestamp.fromDate(event.createdAt.toUtc()),
    'updatedAt': Timestamp.fromDate(event.updatedAt.toUtc()),
    'createdByUserId': event.createdByUserId,
    'updatedByUserId': event.updatedByUserId,
    'deletedAt': event.deletedAt == null
        ? null
        : Timestamp.fromDate(event.deletedAt!.toUtc()),
    'schemaVersion': event.schemaVersion,
  };

  static HuntEvent fromFirestore(
    Map<String, dynamic> data, {
    required String eventId,
    required String localDogId,
    String? localDogKey,
  }) {
    final id = data['eventId'];
    final sessionId = data['sessionId'];
    final type = data['type'];
    final source = data['source'];
    final occurredAt = _dateTime(data['occurredAt']);
    final createdAt = _dateTime(data['createdAt']);
    final updatedAt = _dateTime(data['updatedAt']);
    final creator = data['createdByUserId'];
    if (id != eventId ||
        sessionId is! String ||
        !HuntEventType.values.any((value) => value.name == type) ||
        !HuntEventSource.values.any((value) => value.name == source) ||
        occurredAt == null ||
        createdAt == null ||
        updatedAt == null ||
        creator is! String ||
        creator.trim().isEmpty) {
      throw const FormatException('Invalid HuntEvent cloud payload.');
    }
    return HuntEvent(
      id: eventId,
      sessionId: sessionId,
      dogId: localDogId,
      dogKey: localDogKey,
      type: HuntEventType.values.byName(type as String),
      occurredAt: occurredAt,
      sourceTrackId: data['sourceTrackId'] as String?,
      trackPointIndex: data['trackPointIndex'] as int?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      birdSpecies: data['birdSpecies'] as String?,
      note: data['note'] as String?,
      source: HuntEventSource.values.byName(source as String),
      sourceWaypointName: data['sourceWaypointName'] as String?,
      sourceWaypointSymbol: data['sourceWaypointSymbol'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdByUserId: creator,
      updatedByUserId: data['updatedByUserId'] as String?,
      deletedAt: _dateTime(data['deletedAt']),
      schemaVersion:
          data['schemaVersion'] as int? ?? HuntEvent.currentSchemaVersion,
    );
  }
}

DateTime? _dateTime(Object? value) {
  if (value is Timestamp) return value.toDate().toUtc();
  if (value is DateTime) return value.toUtc();
  if (value is String) return DateTime.tryParse(value)?.toUtc();
  return null;
}
