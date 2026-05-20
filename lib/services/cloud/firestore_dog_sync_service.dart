import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../data/hive_boxes.dart';
import '../../data/local/local_membership_repository.dart';
import '../../models/dog.dart';
import '../../models/dog_membership.dart';
import '../../models/dog_sex.dart';
import 'sync_merge_policy.dart';

class FirestoreDogSyncService {
  FirestoreDogSyncService._();

  static final FirestoreDogSyncService instance = FirestoreDogSyncService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final LocalDogMembershipRepository _membershipRepository =
      LocalDogMembershipRepository();

  static const String _logPrefix = '[CLOUD][DOG]';

  static void _printLog(String message) {
    // ignore: avoid_print
    print(message);
  }

  static void _log(String message) => debugPrint('$_logPrefix $message');

  static void _logError(String message, Object error, StackTrace? stackTrace) {
    debugPrint('$_logPrefix $message: $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  @visibleForTesting
  static Map<String, dynamic> buildUpsertPayload({
    required Dog dog,
    required String cloudDogId,
    required String cloudOwnerUid,
  }) {
    return <String, dynamic>{
      'id': cloudDogId,
      'name': dog.name,
      'nickname': dog.nickname,
      'breed': dog.breed,
      'birthDate': dog.birthDate != null
          ? Timestamp.fromDate(dog.birthDate!.toUtc())
          : null,
      'regNr': dog.regNr,
      'regNrDisplay': dog.regNrDisplay,
      'pedigreeUrl': dog.pedigreeUrl,
      'ownerUserId': dog.ownerUserId,
      'ownerEmail': dog.ownerEmail,
      'title': dog.title,
      'sex': dog.sex.name,
      'deceasedAt': dog.deceasedAt != null
          ? Timestamp.fromDate(dog.deceasedAt!.toUtc())
          : null,
      'memorialNote': dog.memorialNote,
      'profileHeroTextAnchor': dog.profileHeroTextAnchor,
      'profileHeroTextScale': dog.profileHeroTextScale,
      'watermarkShowTitle': dog.watermarkShowTitle,
      'watermarkShowName': dog.watermarkShowName,
      'watermarkShowOfficialName': dog.watermarkShowOfficialName,
      'watermarkShowNickname': dog.watermarkShowNickname,
      'watermarkUseDarkText': dog.watermarkUseDarkText,
      'updatedAt': Timestamp.fromDate(dog.updatedAt.toUtc()),
      'deletedAt': FieldValue.delete(),
      'cloudOwnerUid': cloudOwnerUid,
    };
  }

  Future<Dog> upsertDog(Dog dog) async {
    if (dog.deletedAt != null) {
      await tombstoneDog(dog);
      return dog;
    }

    debugPrint('[CLOUD][DOG] sync start: ${dog.id} ${dog.name}');
    final user = _auth.currentUser;
    if (user == null) {
      _log('Skipping upsert because there is no authenticated user');
      return dog;
    }

    final firebaseUid = user.uid;
    if (firebaseUid.isEmpty) {
      _log('Skipping upsert because authenticated user uid is empty');
      return dog;
    }

    final hasCloudId = dog.cloudId?.isNotEmpty == true;
    final cloudDogId = hasCloudId ? dog.cloudId! : dog.id;
    final hasOwner = dog.cloudOwnerUid?.isNotEmpty == true;
    final cloudOwnerUid = hasOwner ? dog.cloudOwnerUid! : firebaseUid;
    final payload = buildUpsertPayload(
      dog: dog,
      cloudDogId: cloudDogId,
      cloudOwnerUid: cloudOwnerUid,
    );

    final dogRef = _firestore.collection('dogs').doc(cloudDogId);

    try {
      final existingSnapshot = await dogRef.get();
      if (existingSnapshot.exists) {
        final existingData = existingSnapshot.data();
        if (existingData != null) {
          final cloudDog = mapFirestoreDogToDog(existingData, cloudDogId);
          final decision = SyncMergePolicy.forDog(local: dog, cloud: cloudDog);
          switch (decision) {
            case MergeDecision.cloudNewer:
              _logMergeDecision(
                entity: 'dog',
                decision: 'cloud newer',
                id: cloudDogId,
                localUpdatedAt: dog.updatedAt,
                cloudUpdatedAt: cloudDog.updatedAt,
              );
              return _preserveLocalDogIdentity(
                localDog: dog,
                cloudDog: cloudDog,
              );
            case MergeDecision.equal:
              _logMergeDecision(
                entity: 'dog',
                decision: 'equal/noop',
                id: cloudDogId,
                localUpdatedAt: dog.updatedAt,
                cloudUpdatedAt: cloudDog.updatedAt,
              );
              return _preserveLocalDogIdentity(
                localDog: dog,
                cloudDog: cloudDog,
              );
            case MergeDecision.localNewer:
              _logMergeDecision(
                entity: 'dog',
                decision: 'local newer',
                id: cloudDogId,
                localUpdatedAt: dog.updatedAt,
                cloudUpdatedAt: cloudDog.updatedAt,
              );
              break;
            case MergeDecision.insert:
              break;
          }
        }
      }

      debugPrint('[CLOUD][DOG] writing dogs/$cloudDogId');
      await dogRef.set(payload, SetOptions(merge: true));
      debugPrint('[CLOUD][DOG] sync success: $cloudDogId');
      _log('Wrote dog document $cloudDogId for ${dog.dogKey}');
      await _ensureOwnerMember(cloudDogId, firebaseUid);
    } catch (error, stackTrace) {
      debugPrint('[CLOUD][DOG] sync error: $error');
      debugPrint('$stackTrace');
      _logError('upsertDog failed for ${dog.dogKey}', error, stackTrace);
      rethrow;
    }

    return dog.copyWith(
      cloudId: cloudDogId,
      cloudOwnerUid: cloudOwnerUid,
    );
  }

  Future<void> tombstoneDog(Dog dog) async {
    final user = _auth.currentUser;
    if (user == null) {
      _log('Skipping dog tombstone because there is no authenticated user');
      throw StateError('Missing authenticated user for dog tombstone.');
    }

    final firebaseUid = user.uid.trim();
    if (firebaseUid.isEmpty) {
      _log('Skipping dog tombstone because authenticated user uid is empty');
      throw StateError('Missing authenticated user uid for dog tombstone.');
    }

    final cloudDogId =
        (dog.cloudId?.isNotEmpty == true) ? dog.cloudId! : dog.id;
    final cloudOwnerUid = (dog.cloudOwnerUid?.isNotEmpty == true)
        ? dog.cloudOwnerUid!
        : firebaseUid;
    final deletedAt = (dog.deletedAt ?? dog.updatedAt).toUtc();

    await _firestore.collection('dogs').doc(cloudDogId).set(
          <String, dynamic>{
            'id': cloudDogId,
            'dogKey': dog.dogKey,
            'regNrDisplay': dog.regNrDisplay,
            'cloudOwnerUid': cloudOwnerUid,
            'updatedAt': Timestamp.fromDate(deletedAt),
            'deletedAt': Timestamp.fromDate(deletedAt),
            'lastSyncedAt': FieldValue.serverTimestamp(),
          }..removeWhere((key, value) => value == null),
          SetOptions(merge: true),
        );

    _printLog('[SYNC][DELETE] push dog tombstone success: $cloudDogId');
    _printLog('[SYNC][DELETE] complete dogId=$cloudDogId');
  }

  Future<void> tombstoneDogBestEffort(Dog dog) async {
    try {
      await tombstoneDog(dog);
    } catch (_) {
      // Local tombstone stays source of truth until outbox catches up.
    }
  }

  Future<List<Map<String, dynamic>>> fetchAccessibleDogs() async {
    _printLog('[CLOUD][DOG] fetch start');

    final user = _auth.currentUser;
    if (user == null || user.uid.isEmpty) {
      _printLog('[CLOUD][DOG] fetch memberships count: 0');
      _printLog('[CLOUD][DOG] fetch done: 0 dogs');
      return const [];
    }

    final dogs = <Map<String, dynamic>>[];
    final dogRefs = await _fetchAccessibleDogRefs(user.uid);
    _printLog('[CLOUD][DOG] fetch memberships count: ${dogRefs.length}');

    for (final dogRef in dogRefs) {
      final dogSnapshot = await dogRef.get();
      final dogData = dogSnapshot.data();
      if (!dogSnapshot.exists || dogData == null) {
        continue;
      }

      dogs.add(dogData);
      _printLog('[CLOUD][DOG] fetched dog: ${dogRef.id}');
    }

    _printLog('[CLOUD][DOG] fetch done: ${dogs.length} dogs');
    return dogs;
  }

  Dog mapFirestoreDogToDog(Map<String, dynamic> data, String dogId) {
    final name = _readString(data['name']) ?? 'Ukjent';
    final dogKey = _readString(data['dogKey']) ?? dogId;
    final regNrDisplay = _readString(data['regNrDisplay']) ?? '';
    final updatedAt = _readDateTime(data['updatedAt']) ?? _epoch();
    final profileHeroTextAnchor =
        _readString(data['profileHeroTextAnchor']) ?? 'bottomLeft';
    final profileHeroTextScale =
        _readDouble(data['profileHeroTextScale']) ?? 1.0;
    final watermarkShowTitle = _readBool(data['watermarkShowTitle']) ?? true;
    final watermarkShowName = _readBool(data['watermarkShowName']) ?? true;
    final watermarkShowOfficialName =
        _readBool(data['watermarkShowOfficialName']) ?? true;
    final watermarkShowNickname =
        _readBool(data['watermarkShowNickname']) ?? true;
    final watermarkUseDarkText =
        _readBool(data['watermarkUseDarkText']) ?? false;

    return Dog(
      id: _readString(data['id']) ?? dogId,
      name: name,
      dogKey: dogKey,
      regNrDisplay: regNrDisplay,
      imagePath: _readString(data['imagePath']),
      birthDate: _readDateTime(data['birthDate']),
      pedigreeUrl: _readString(data['pedigreeUrl']),
      breed: _readString(data['breed']),
      ownerUserId: _readString(data['ownerUserId']) ??
          _readString(data['cloudOwnerUid']),
      ownerEmail: _readString(data['ownerEmail']),
      title: _readString(data['title']),
      updatedAt: updatedAt,
      regNr: _readString(data['regNr']),
      sex: _readDogSex(data['sex']),
      deceasedAt: _readDateTime(data['deceasedAt']),
      memorialNote: _readString(data['memorialNote']),
      profileHeroTextAnchor: profileHeroTextAnchor,
      profileHeroTextScale: profileHeroTextScale,
      nickname: _readString(data['nickname']),
      watermarkShowTitle: watermarkShowTitle,
      watermarkShowName: watermarkShowName,
      watermarkShowOfficialName: watermarkShowOfficialName,
      watermarkShowNickname: watermarkShowNickname,
      watermarkUseDarkText: watermarkUseDarkText,
      cloudId: dogId,
      cloudOwnerUid: _readString(data['cloudOwnerUid']),
      deletedAt: _readDateTime(data['deletedAt']),
    );
  }

  Future<List<Dog>> fetchAccessibleDogsAsModels({
    DateTime? updatedAfter,
  }) async {
    final user = _auth.currentUser;
    final uid = user?.uid;
    _printLog('[CLOUD][DOG] fetch accessible dogs for uid: ${uid ?? 'null'}');

    if (uid == null || uid.isEmpty) {
      _printLog('[CLOUD][DOG] mapped dogs count: 0');
      return const [];
    }

    if (updatedAfter != null) {
      debugPrint(
        '[SYNC][DELTA] full fetch fallback: '
        'reason=visible dogs require membership lookup cursor='
        '${updatedAfter.toUtc().toIso8601String()}',
      );
    }

    try {
      final dogs = <Dog>[];
      final dogRefs = await _fetchAccessibleDogRefs(uid);
      for (final dogRef in dogRefs) {
        final dogSnapshot = await dogRef.get();
        final dogData = dogSnapshot.data();
        if (!dogSnapshot.exists || dogData == null) {
          continue;
        }

        _printLog('[CLOUD][DOG] mapping dog: ${dogRef.id}');
        dogs.add(mapFirestoreDogToDog(dogData, dogRef.id));
      }

      _printLog('[CLOUD][DOG] mapped dogs count: ${dogs.length}');
      return dogs;
    } catch (error) {
      _printLog('[CLOUD][DOG] fetch failed: $error');
      rethrow;
    }
  }

  Future<List<DocumentReference<Map<String, dynamic>>>> _fetchAccessibleDogRefs(
    String uid,
  ) async {
    _printLog('[CLOUD][DOG] membership query start');
    try {
      final membershipSnapshot = await _firestore
          .collectionGroup('members')
          .where('uid', isEqualTo: uid)
          .get();

      final dogRefs = <DocumentReference<Map<String, dynamic>>>[];
      final dogIds = <String>[];

      for (final membershipDoc in membershipSnapshot.docs) {
        final dogRef = membershipDoc.reference.parent.parent;
        if (dogRef == null) {
          continue;
        }
        dogRefs.add(dogRef);
        dogIds.add(dogRef.id);
      }

      _printLog(
        '[CLOUD][DOG] membership query success count: ${dogRefs.length}',
      );
      _printLog('[CLOUD][DOG] membership dog ids: $dogIds');
      return dogRefs;
    } catch (error) {
      _printLog('[CLOUD][DOG] membership query failed: $error');
      rethrow;
    }
  }

  Future<int> restoreAccessibleDogsToHive() async {
    _printLog('[CLOUD][DOG] restore started');

    try {
      final cloudDogs = await fetchAccessibleDogsAsModels();
      final uid = _auth.currentUser?.uid;
      final box = dogsBox();
      var inserted = 0;

      for (final cloudDog in cloudDogs) {
        final cloudDogId = cloudDog.cloudId;
        if (cloudDogId == null || cloudDogId.isEmpty) {
          _printLog('[CLOUD][DOG] restore skipped missing cloudId');
          continue;
        }

        _printLog('[CLOUD][DOG] restore candidate: $cloudDogId');

        final localEntry = _findLocalDogEntryForCloudDog(box, cloudDog);
        if (localEntry == null) {
          if (cloudDog.deletedAt != null) {
            _printLog(
              '[SYNC][DELETE] pull dog tombstone applied locally: '
              '$cloudDogId already_missing=true',
            );
            continue;
          }

          await box.add(cloudDog);
          inserted++;
          _logMergeDecision(
            entity: 'dog',
            decision: 'insert local missing',
            id: cloudDogId,
            cloudUpdatedAt: cloudDog.updatedAt,
          );
          if (uid != null && uid.isNotEmpty) {
            await _ensureLocalMembershipForDog(cloudDog, uid);
          }
          continue;
        }

        final localDog = localEntry.value;
        if (cloudDog.deletedAt != null) {
          if (localDog.updatedAt.toUtc().isAfter(cloudDog.deletedAt!.toUtc())) {
            _logMergeDecision(
              entity: 'dog',
              decision: 'local newer',
              id: cloudDogId,
              localUpdatedAt: localDog.updatedAt,
              cloudUpdatedAt: cloudDog.updatedAt,
            );
            continue;
          }

          await box.put(
            localEntry.key,
            _preserveLocalDogIdentity(
              localDog: localDog,
              cloudDog: cloudDog,
            ),
          );
          _printLog(
              '[SYNC][DELETE] pull dog tombstone applied locally: $cloudDogId');
          _printLog('[SYNC][DELETE] dog hidden from visibility: $cloudDogId');
          continue;
        }

        final decision = SyncMergePolicy.forDog(
          local: localDog,
          cloud: cloudDog,
        );

        switch (decision) {
          case MergeDecision.cloudNewer:
            _logMergeDecision(
              entity: 'dog',
              decision: 'cloud newer',
              id: cloudDogId,
              localUpdatedAt: localDog.updatedAt,
              cloudUpdatedAt: cloudDog.updatedAt,
            );
            await box.put(
              localEntry.key,
              _preserveLocalDogIdentity(
                localDog: localDog,
                cloudDog: cloudDog,
              ),
            );
            break;
          case MergeDecision.localNewer:
            _logMergeDecision(
              entity: 'dog',
              decision: 'local newer',
              id: cloudDogId,
              localUpdatedAt: localDog.updatedAt,
              cloudUpdatedAt: cloudDog.updatedAt,
            );
            break;
          case MergeDecision.equal:
            _logMergeDecision(
              entity: 'dog',
              decision: 'equal/noop',
              id: cloudDogId,
              localUpdatedAt: localDog.updatedAt,
              cloudUpdatedAt: cloudDog.updatedAt,
            );
            break;
          case MergeDecision.insert:
            break;
        }

        var mergedDog = box.get(localEntry.key) ?? localDog;
        if (uid != null &&
            uid.isNotEmpty &&
            cloudDog.cloudOwnerUid == uid &&
            (mergedDog.ownerUserId != uid ||
                mergedDog.cloudOwnerUid != uid ||
                mergedDog.cloudId != cloudDog.cloudId)) {
          mergedDog = mergedDog.copyWith(
            ownerUserId: uid,
            cloudOwnerUid: uid,
            cloudId: cloudDog.cloudId,
          );
          await box.put(localEntry.key, mergedDog);
          _printLog(
            '[CLOUD][DOG] corrected local owner metadata: '
            'dogId=${mergedDog.id} cloudId=${mergedDog.cloudId} uid=$uid',
          );
        }
        if (uid != null && uid.isNotEmpty) {
          await _ensureLocalMembershipForDog(mergedDog, uid);
        }
      }

      _printLog('[CLOUD][DOG] restore complete inserted: $inserted');
      return inserted;
    } catch (error) {
      _printLog('[CLOUD][DOG] restore failed: $error');
      rethrow;
    }
  }

  String? _readString(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }

  DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  double? _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  bool? _readBool(dynamic value) {
    return value is bool ? value : null;
  }

  DogSex? _readDogSex(dynamic value) {
    if (value is DogSex) {
      return value;
    }
    if (value is String) {
      for (final sex in DogSex.values) {
        if (sex.name == value) {
          return sex;
        }
      }
    }
    return null;
  }

  MapEntry<dynamic, Dog>? _findLocalDogEntryForCloudDog(
    Box<Dog> box,
    Dog cloudDog,
  ) {
    final cloudId = cloudDog.cloudId;
    for (final entry in box.toMap().entries) {
      final localDog = entry.value;
      if (cloudId != null &&
          cloudId.isNotEmpty &&
          localDog.cloudId == cloudId) {
        return MapEntry(entry.key, localDog);
      }
      if (localDog.id == cloudDog.id) {
        return MapEntry(entry.key, localDog);
      }
    }
    return null;
  }

  Dog _preserveLocalDogIdentity({
    required Dog localDog,
    required Dog cloudDog,
  }) {
    return cloudDog.copyWith(
      id: localDog.id,
      dogKey: localDog.dogKey.isNotEmpty ? localDog.dogKey : cloudDog.dogKey,
    );
  }

  Future<void> _ensureLocalMembershipForDog(Dog dog, String uid) async {
    if (dog.isDeleted) {
      _printLog(
          '[SYNC][DELETE] dog hidden from visibility: ${dog.cloudId ?? dog.id}');
      return;
    }

    final existing = await _membershipRepository.getMembership(dog.dogKey, uid);
    if (existing != null) {
      _printLog(
        '[LOCAL][DOG] restore membership skipped existing: dogId=${dog.id} uid=$uid',
      );
      return;
    }

    final role = dog.cloudOwnerUid == uid ? Role.owner : Role.viewer;
    final membership = DogMembership(
      dogKey: dog.dogKey,
      userId: uid,
      role: role,
      status: Status.active,
      addedAt: DateTime.now(),
      addedByUserId: uid,
    );
    await _membershipRepository.upsertMembership(membership);
    _printLog(
      '[LOCAL][DOG] restore membership inserted: dogId=${dog.id} uid=$uid',
    );
  }

  Future<void> _ensureOwnerMember(String dogId, String uid) async {
    if (dogId.isEmpty) {
      _log('ensureOwnerMember skipped because dogId is empty');
      return;
    }
    if (uid.isEmpty) {
      _log('ensureOwnerMember skipped because uid is empty');
      return;
    }

    final memberRef =
        _firestore.collection('dogs').doc(dogId).collection('members').doc(uid);

    try {
      final snapshot = await memberRef.get();
      final data = <String, dynamic>{
        'uid': uid,
        'role': 'owner',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!snapshot.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }
      await memberRef.set(data, SetOptions(merge: true));
      _log('Ensured owner member $uid for dog $dogId');
    } catch (error, stackTrace) {
      _logError(
        'ensureOwnerMember failed for $dogId & $uid',
        error,
        stackTrace,
      );
    }
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
