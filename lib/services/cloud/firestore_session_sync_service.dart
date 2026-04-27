import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../data/hive_boxes.dart';
import '../../models/dog.dart';
import '../../models/hunt_session.dart';
import '../../models/session_type.dart';
import 'sync_merge_policy.dart';

class FirestoreSessionSyncService {
  FirestoreSessionSyncService._();

  static final FirestoreSessionSyncService instance =
      FirestoreSessionSyncService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static void _printLog(String message) {
    // ignore: avoid_print
    print(message);
  }

  Map<String, dynamic> mapSessionToFirestore({
    required String sessionId,
    required HuntSession session,
    required String cloudDogId,
  }) {
    final startedAtUtc = session.dateTime.toUtc();
    final endedAtUtc = startedAtUtc.add(
      Duration(minutes: _nonNegative(session.durationMinutes)),
    );

    final payload = <String, dynamic>{
      'id': sessionId,
      'sessionId': sessionId,
      'dogId': session.dogId,
      'cloudDogId': cloudDogId,
      'dogKey': _nonEmptyString(session.dogKey),
      'dateTime': Timestamp.fromDate(startedAtUtc),
      'startedAt': Timestamp.fromDate(startedAtUtc),
      'endedAt': Timestamp.fromDate(endedAtUtc),
      'durationMinutes': _nonNegative(session.durationMinutes),
      'location': session.location,
      'birdsSeen': _nonNegative(session.birdsSeen),
      'points': _nonNegative(session.points),
      'secondaryPoints': _nonNegative(session.secondaryPoints),
      'flushes': _nonNegative(session.flushes),
      'notes': session.notes.trim(),
      'birdSpecies': _stringList(session.birdSpecies),
      'trackId': _nonEmptyString(session.trackId),
      'createdByUserId': _nonEmptyString(session.createdByUserId),
      'sessionType': session.sessionType.name,
      'birdsShotCount': _nonNegative(session.birdsShotCount),
      'birdsShotSpecies': _nonEmptyString(session.birdsShotSpecies),
      'updatedAt': Timestamp.fromDate(session.updatedAt.toUtc()),
      'deletedAt': session.deletedAt != null
          ? Timestamp.fromDate(session.deletedAt!.toUtc())
          : FieldValue.delete(),
      'lastSyncedAt': FieldValue.serverTimestamp(),
    };

    payload.removeWhere((key, value) => value == null);
    return payload;
  }

  Future<void> upsertSession({
    required String sessionId,
    required HuntSession session,
  }) async {
    if (session.deletedAt != null) {
      await tombstoneSession(sessionId: sessionId, session: session);
      return;
    }

    _printLog('[CLOUD][SESSION] sync requested: $sessionId');
    _printLog('[CLOUD][SESSION] sync start: $sessionId');

    final dog = _findLocalDogById(session.dogId);
    final cloudDogId = dog?.cloudId;
    if (cloudDogId == null || cloudDogId.isEmpty) {
      _printLog(
        '[CLOUD][SESSION] skip sync, dog missing cloudId: '
        'sessionId=$sessionId dogId=${session.dogId}',
      );
      return;
    }

    final currentUid = _auth.currentUser?.uid;
    final payload = mapSessionToFirestore(
      sessionId: sessionId,
      session: session.copyWith(
        createdByUserId: session.createdByUserId ?? _nonEmptyString(currentUid),
        updatedAt: session.updatedAt,
      ),
      cloudDogId: cloudDogId,
    );

    final sessionRef = _firestore
        .collection('dogs')
        .doc(cloudDogId)
        .collection('sessions')
        .doc(sessionId);

    try {
      final existingSnapshot = await sessionRef.get();
      if (existingSnapshot.exists) {
        final existingData = existingSnapshot.data();
        if (existingData != null) {
          final cloudSession = mapFirestoreSessionToSession(
            existingData,
            sessionId,
            cloudDogId,
          );
          final decision = SyncMergePolicy.forSession(
            local: session,
            cloud: cloudSession,
          );
          switch (decision) {
            case MergeDecision.cloudNewer:
              _logMergeDecision(
                entity: 'session',
                decision: 'cloud newer',
                id: sessionId,
                localUpdatedAt: session.updatedAt,
                cloudUpdatedAt: cloudSession.updatedAt,
              );
              return;
            case MergeDecision.equal:
              _logMergeDecision(
                entity: 'session',
                decision: 'equal/noop',
                id: sessionId,
                localUpdatedAt: session.updatedAt,
                cloudUpdatedAt: cloudSession.updatedAt,
              );
              return;
            case MergeDecision.localNewer:
              _logMergeDecision(
                entity: 'session',
                decision: 'local newer',
                id: sessionId,
                localUpdatedAt: session.updatedAt,
                cloudUpdatedAt: cloudSession.updatedAt,
              );
              break;
            case MergeDecision.insert:
              break;
          }
        }
      }

      _printLog(
          '[CLOUD][SESSION] writing dogs/$cloudDogId/sessions/$sessionId');
      await sessionRef.set(payload, SetOptions(merge: true));
      _printLog('[CLOUD][SESSION] sync success: $sessionId');
    } catch (error, stackTrace) {
      _printLog('[CLOUD][SESSION] sync failed: $sessionId error=$error');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  Future<void> upsertSessionBestEffort({
    required String sessionId,
    required HuntSession session,
  }) async {
    try {
      await upsertSession(sessionId: sessionId, session: session);
    } catch (_) {
      // Local Hive remains source of truth; cloud sync is best effort.
    }
  }

  Future<void> tombstoneSession({
    required String sessionId,
    required HuntSession session,
  }) async {
    final dog = _findLocalDogById(session.dogId);
    final cloudDogId = dog?.cloudId;
    if (cloudDogId == null || cloudDogId.isEmpty) {
      _printLog(
        '[SYNC][DELETE] push tombstone skipped missing cloud dog: '
        'sessionId=$sessionId dogId=${session.dogId}',
      );
      throw StateError('Missing cloud dog id for session tombstone.');
    }

    final deletedAt = (session.deletedAt ?? session.updatedAt).toUtc();
    final sessionRef = _firestore
        .collection('dogs')
        .doc(cloudDogId)
        .collection('sessions')
        .doc(sessionId);

    await sessionRef.set(
      <String, dynamic>{
        'id': sessionId,
        'sessionId': sessionId,
        'dogId': session.dogId,
        'cloudDogId': cloudDogId,
        'dogKey': _nonEmptyString(session.dogKey),
        'updatedAt': Timestamp.fromDate(deletedAt),
        'deletedAt': Timestamp.fromDate(deletedAt),
        'lastSyncedAt': FieldValue.serverTimestamp(),
      }..removeWhere((key, value) => value == null),
      SetOptions(merge: true),
    );

    _printLog('[SYNC][DELETE] push tombstone success: $sessionId');
    _printLog('[SYNC][DELETE] complete sessionId=$sessionId');
  }

  Future<void> tombstoneSessionBestEffort({
    required String sessionId,
    required HuntSession session,
  }) async {
    try {
      await tombstoneSession(sessionId: sessionId, session: session);
    } catch (_) {
      // Local delete stays source of truth until outbox catches up.
    }
  }

  HuntSession mapFirestoreSessionToSession(
    Map<String, dynamic> data,
    String sessionId,
    String dogCloudId,
  ) {
    final startedAt = _readDateTime(data['dateTime']) ??
        _readDateTime(data['startedAt']) ??
        _epoch();
    final endedAt = _readDateTime(data['endedAt']);
    final durationMinutes = _readInt(data['durationMinutes']) ??
        _durationFromRange(startedAt, endedAt);
    final updatedAt = _readDateTime(data['updatedAt']) ??
        _readDateTime(data['lastSyncedAt']) ??
        startedAt;
    final deletedAt = _readDateTime(data['deletedAt']);

    return HuntSession(
      dogId: _readString(data['dogId']) ?? dogCloudId,
      dogKey: _readString(data['dogKey']),
      dateTime: startedAt,
      location: _readLocation(data['location']),
      durationMinutes: _nonNegative(durationMinutes),
      birdsSeen: _nonNegative(_readInt(data['birdsSeen']) ?? 0),
      points: _nonNegative(_readInt(data['points']) ?? 0),
      flushes: _nonNegative(_readInt(data['flushes']) ?? 0),
      notes: _readString(data['notes']) ?? '',
      secondaryPoints: _nonNegative(_readInt(data['secondaryPoints']) ?? 0),
      trackId: _readString(data['trackId']),
      birdSpecies: _stringList(_readStringList(data['birdSpecies'])),
      mediaPaths: _stringList(_readStringList(data['mediaPaths'])),
      createdByUserId:
          _readString(data['createdByUserId']) ?? _readString(data['ownerUid']),
      sessionType: sessionTypeFromString(_readString(data['sessionType'])),
      birdsShotCount: _nonNegative(_readInt(data['birdsShotCount']) ?? 0),
      birdsShotSpecies: _readString(data['birdsShotSpecies']),
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  Future<List<HuntSession>> fetchSessionsForDogAsModels(
    String? dogCloudId, {
    DateTime? updatedAfter,
  }) async {
    if (dogCloudId == null || dogCloudId.trim().isEmpty) {
      _printLog('[CLOUD][SESSION] fetch skipped, missing dogCloudId');
      return const [];
    }

    final normalizedDogCloudId = dogCloudId.trim();
    _printLog('[CLOUD][SESSION] fetch start for dog: $normalizedDogCloudId');

    try {
      final entries = await _fetchSessionEntriesForDog(
        normalizedDogCloudId,
        updatedAfter: updatedAfter,
      );
      final sessions =
          entries.map((entry) => entry.value).toList(growable: false);

      _printLog('[CLOUD][SESSION] mapped sessions count: ${sessions.length}');
      return sessions;
    } catch (error) {
      _printLog(
        '[CLOUD][SESSION] fetch failed for dog: '
        '$normalizedDogCloudId error=$error',
      );
      rethrow;
    }
  }

  Future<List<HuntSession>> fetchSessionEntriesForDogAsModels(
    String? dogCloudId, {
    DateTime? updatedAfter,
  }) async {
    final entries = await _fetchSessionEntriesForDog(
      dogCloudId ?? '',
      updatedAfter: updatedAfter,
    );
    return entries.map((entry) => entry.value).toList();
  }

  Future<List<MapEntry<String, HuntSession>>> fetchSessionEntriesWithIdsForDog(
    String? dogCloudId, {
    DateTime? updatedAfter,
  }) async {
    if (dogCloudId == null || dogCloudId.trim().isEmpty) {
      _printLog('[CLOUD][SESSION] fetch entries skipped, missing dogCloudId');
      return const [];
    }
    return _fetchSessionEntriesForDog(
      dogCloudId.trim(),
      updatedAfter: updatedAfter,
    );
  }

  Future<int> restoreSessionsForDogToHive(String? dogCloudId) async {
    if (dogCloudId == null || dogCloudId.trim().isEmpty) {
      _printLog('[CLOUD][SESSION] restore skipped, missing dogCloudId');
      return 0;
    }

    final normalizedDogCloudId = dogCloudId.trim();
    _printLog(
        '[CLOUD][SESSION] restore started for dog: $normalizedDogCloudId');

    final localDog = _findLocalDogByCloudId(dogsBox(), normalizedDogCloudId);
    if (localDog == null) {
      _printLog(
        '[CLOUD][SESSION] restore skipped, no local dog for cloudId: '
        '$normalizedDogCloudId',
      );
      return 0;
    }

    try {
      final entries = await _fetchSessionEntriesForDog(normalizedDogCloudId);
      final box = sessionsBox();
      var inserted = 0;

      for (final entry in entries) {
        final sessionId = entry.key;
        final hiveKey = _resolveSessionHiveKey(sessionId);
        final cloudSession = entry.value.copyWith(
          dogId: localDog.id,
          dogKey: localDog.dogKey,
          updatedAt: entry.value.updatedAt,
        );
        _printLog('[CLOUD][SESSION] restore candidate: $sessionId');

        final localSession = box.get(hiveKey);
        if (localSession == null) {
          await box.put(hiveKey, cloudSession);
          inserted++;
          _logMergeDecision(
            entity: 'session',
            decision: 'insert local missing',
            id: sessionId,
            cloudUpdatedAt: cloudSession.updatedAt,
          );
          continue;
        }

        final decision = SyncMergePolicy.forSession(
          local: localSession,
          cloud: cloudSession,
        );

        switch (decision) {
          case MergeDecision.cloudNewer:
            _logMergeDecision(
              entity: 'session',
              decision: 'cloud newer',
              id: sessionId,
              localUpdatedAt: localSession.updatedAt,
              cloudUpdatedAt: cloudSession.updatedAt,
            );
            await box.put(hiveKey, cloudSession);
            break;
          case MergeDecision.localNewer:
            _logMergeDecision(
              entity: 'session',
              decision: 'local newer',
              id: sessionId,
              localUpdatedAt: localSession.updatedAt,
              cloudUpdatedAt: cloudSession.updatedAt,
            );
            break;
          case MergeDecision.equal:
            _logMergeDecision(
              entity: 'session',
              decision: 'equal/noop',
              id: sessionId,
              localUpdatedAt: localSession.updatedAt,
              cloudUpdatedAt: cloudSession.updatedAt,
            );
            break;
          case MergeDecision.insert:
            break;
        }
      }

      _printLog(
        '[CLOUD][SESSION] restore complete inserted: $inserted '
        'for dog: $normalizedDogCloudId',
      );
      return inserted;
    } catch (error) {
      _printLog(
        '[CLOUD][SESSION] restore failed for dog: '
        '$normalizedDogCloudId error=$error',
      );
      rethrow;
    }
  }

  Dog? _findLocalDogById(String dogId) {
    for (final dog in dogsBox().values) {
      if (dog.id == dogId) {
        return dog;
      }
    }
    return null;
  }

  Dog? _findLocalDogByCloudId(Box<Dog> box, String cloudId) {
    for (final dog in box.values) {
      if (dog.cloudId == cloudId) {
        return dog;
      }
    }
    return null;
  }

  Future<List<MapEntry<String, HuntSession>>> _fetchSessionEntriesForDog(
    String dogCloudId, {
    DateTime? updatedAfter,
  }) async {
    QuerySnapshot<Map<String, dynamic>> snapshot;

    if (updatedAfter != null) {
      try {
        snapshot = await _firestore
            .collection('dogs')
            .doc(dogCloudId)
            .collection('sessions')
            .where(
              'updatedAt',
              isGreaterThan: Timestamp.fromDate(updatedAfter.toUtc()),
            )
            .get();
        debugPrint(
          '[SYNC][DELTA] session delta fetch count: ${snapshot.docs.length} '
          'for dog: $dogCloudId',
        );
      } on FirebaseException catch (error) {
        debugPrint(
          '[SYNC][DELTA] full fetch fallback: '
          'reason=session delta query failed code=${error.code} '
          'for dog: $dogCloudId',
        );
        snapshot = await _firestore
            .collection('dogs')
            .doc(dogCloudId)
            .collection('sessions')
            .get();
      }
    } else {
      snapshot = await _firestore
          .collection('dogs')
          .doc(dogCloudId)
          .collection('sessions')
          .get();
    }

    final entries = <MapEntry<String, HuntSession>>[];
    for (final doc in snapshot.docs) {
      _printLog('[CLOUD][SESSION] mapping session: ${doc.id}');
      entries.add(
        MapEntry(
          doc.id,
          mapFirestoreSessionToSession(
            doc.data(),
            doc.id,
            dogCloudId,
          ),
        ),
      );
    }
    _printLog(
      '[CLOUD][SESSION] fetch success count: ${snapshot.docs.length} '
      'for dog: $dogCloudId',
    );
    return entries;
  }

  int _nonNegative(int value) => value < 0 ? 0 : value;

  dynamic _resolveSessionHiveKey(String sessionId) {
    final numeric = int.tryParse(sessionId);
    return numeric ?? sessionId;
  }

  int _durationFromRange(DateTime startedAt, DateTime? endedAt) {
    if (endedAt == null) {
      return 0;
    }

    final minutes = endedAt.difference(startedAt).inMinutes;
    return minutes < 0 ? 0 : minutes;
  }

  DateTime? _readDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }

  int? _readInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  String? _nonEmptyString(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _readString(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return _nonEmptyString(value);
    }
    return _nonEmptyString(value.toString());
  }

  String _readLocation(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value is String) {
      return HuntSession.normalizeLocation(value);
    }
    return HuntSession.normalizeLocation(value.toString());
  }

  List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value.map((item) => item.toString()).toList(growable: false);
  }

  List<String> _stringList(List<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  void _logMergeDecision({
    required String entity,
    required String decision,
    required String id,
    DateTime? localUpdatedAt,
    DateTime? cloudUpdatedAt,
  }) {
    debugPrint(
      '[SYNC][MERGE] $entity $decision id=$id '
      'local=${localUpdatedAt?.toIso8601String()} '
      'cloud=${cloudUpdatedAt?.toIso8601String()}',
    );
  }

  DateTime _epoch() => DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
