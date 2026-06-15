import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'app_user.dart';

/// Simple repository for reading the current Firestore users/{uid} profile.
class AppUserRepository {
  AppUserRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Reads the most recent profile for the authenticated user.
  ///
  /// Tries to reuse the local cache first, and falls back to the server if the
  /// document is unavailable locally. Throws [AppUserNotFoundException] if the
  /// document does not exist or cannot be fetched.
  Future<AppUser> getCurrentUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const AppUserRepositoryException(
          'No authenticated user is available');
    }

    final ref = _firestore.collection('users').doc(uid);

    final cached = await _tryGet(ref, Source.cache);
    if (_hasDocument(cached)) {
      return AppUser.fromSnapshot(cached!);
    }

    final server = await _tryGet(ref, Source.server);
    if (_hasDocument(server)) {
      return AppUser.fromSnapshot(server!);
    }

    throw const AppUserNotFoundException();
  }

  bool _hasDocument(DocumentSnapshot<Map<String, dynamic>>? snapshot) =>
      snapshot != null && snapshot.exists;

  Future<DocumentSnapshot<Map<String, dynamic>>?> _tryGet(
    DocumentReference<Map<String, dynamic>> ref,
    Source source,
  ) async {
    try {
      return await ref.get(GetOptions(source: source));
    } on FirebaseException catch (error) {
      debugPrint('[USER] Firestore ${ref.path} source=$source failed: $error');
    } catch (error) {
      debugPrint('[USER] Firestore ${ref.path} source=$source failed: $error');
    }
    return null;
  }
}

class AppUserRepositoryException implements Exception {
  const AppUserRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'AppUserRepositoryException: $message';
}

class AppUserNotFoundException extends AppUserRepositoryException {
  const AppUserNotFoundException()
      : super(
            'Firestore users/{uid} document was not found for the current user');
}
