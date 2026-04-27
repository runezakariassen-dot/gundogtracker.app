// File: lib/remote/services/dog_sync_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:jakthund_app/remote/dto/dog_remote_dto.dart';

class DogSyncService {
  DogSyncService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> syncDog({
    required dynamic dog,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('DogSyncService: User not authenticated');
    }

    final uid = user.uid;
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    final dto = DogRemoteDto.fromDog(
      dog: dog,
      ownerUid: uid,
      nowMs: nowMs,
    );

    if (dto.dogId.isEmpty) {
      throw Exception('DogSyncService: dogId is empty (cannot sync).');
    }

    final batch = _firestore.batch();

    final dogRef = _firestore.collection('dogs').doc(dto.dogId);
    final memberRef = dogRef.collection('members').doc(uid);
    final userRef = _firestore.collection('users').doc(uid);

    batch.set(dogRef, dto.toMap(), SetOptions(merge: true));

    batch.set(
      memberRef,
      <String, dynamic>{
        'uid': uid,
        'role': 'owner',
        'joinedAtMs': nowMs,
      },
      SetOptions(merge: true),
    );

    batch.set(
      userRef,
      <String, dynamic>{
        'uid': uid,
        'lastActiveMs': nowMs,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }
}
