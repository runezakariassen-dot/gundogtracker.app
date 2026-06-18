import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/dog_media_asset.dart';

class DogMediaCloudService {
  DogMediaCloudService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static String profileOriginalStoragePath({
    required String dogId,
    required String mediaId,
  }) {
    return _joinStoragePath(<String>[
      'dogs',
      dogId,
      'profile',
      mediaId,
      'original',
    ]);
  }

  static String profileThumbnailStoragePath({
    required String dogId,
    required String mediaId,
  }) {
    return _joinStoragePath(<String>[
      'dogs',
      dogId,
      'profile',
      mediaId,
      'thumb.jpg',
    ]);
  }

  static String sessionMediaOriginalStoragePath({
    required String dogId,
    required String sessionId,
    required String mediaId,
  }) {
    return _joinStoragePath(<String>[
      'dogs',
      dogId,
      'sessions',
      sessionId,
      'media',
      mediaId,
      'original',
    ]);
  }

  static String sessionMediaThumbnailStoragePath({
    required String dogId,
    required String sessionId,
    required String mediaId,
  }) {
    return _joinStoragePath(<String>[
      'dogs',
      dogId,
      'sessions',
      sessionId,
      'media',
      mediaId,
      'thumb.jpg',
    ]);
  }

  static String firestoreMediaDocumentPath({
    required String dogId,
    required String mediaId,
  }) {
    return _joinStoragePath(<String>['dogs', dogId, 'media', mediaId]);
  }

  static Map<String, dynamic> profileImageMetadataPayload({
    required String dogId,
    required String dogKey,
    required String mediaId,
    String? thumbnailStoragePath,
    String? contentType,
    int? sizeBytes,
    String? createdByUid,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) {
    return _metadataPayload(
      dogId: dogId,
      dogKey: dogKey,
      mediaId: mediaId,
      sessionId: null,
      kind: DogMediaKind.profileImage,
      storagePath: profileOriginalStoragePath(dogId: dogId, mediaId: mediaId),
      thumbnailStoragePath: thumbnailStoragePath,
      contentType: contentType,
      sizeBytes: sizeBytes,
      createdByUid: createdByUid,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static Map<String, dynamic> sessionMediaMetadataPayload({
    required String dogId,
    required String dogKey,
    required String sessionId,
    required String mediaId,
    required DogMediaKind kind,
    String? thumbnailStoragePath,
    String? contentType,
    int? sizeBytes,
    String? createdByUid,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) {
    if (kind == DogMediaKind.profileImage) {
      throw ArgumentError.value(
        kind,
        'kind',
        'Session media kind must be sessionImage or sessionVideo.',
      );
    }
    return _metadataPayload(
      dogId: dogId,
      dogKey: dogKey,
      mediaId: mediaId,
      sessionId: sessionId,
      kind: kind,
      storagePath: sessionMediaOriginalStoragePath(
        dogId: dogId,
        sessionId: sessionId,
        mediaId: mediaId,
      ),
      thumbnailStoragePath: thumbnailStoragePath,
      contentType: contentType,
      sizeBytes: sizeBytes,
      createdByUid: createdByUid,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Future<UploadTask> uploadFileToStorage({
    required File file,
    required String storagePath,
    String? contentType,
  }) async {
    final metadata =
        contentType == null ? null : SettableMetadata(contentType: contentType);
    return _storage.ref(storagePath).putFile(file, metadata);
  }

  Future<void> downloadFileToPath({
    required String storagePath,
    required String localPath,
  }) {
    return _storage.ref(storagePath).writeToFile(File(localPath));
  }

  Future<void> writeMediaMetadata({
    required String dogId,
    required String mediaId,
    required Map<String, dynamic> payload,
  }) {
    return _firestore
        .collection('dogs')
        .doc(dogId)
        .collection('media')
        .doc(mediaId)
        .set(payload, SetOptions(merge: true));
  }

  static Map<String, dynamic> _metadataPayload({
    required String dogId,
    required String dogKey,
    required String mediaId,
    required String? sessionId,
    required DogMediaKind kind,
    required String storagePath,
    required String? thumbnailStoragePath,
    required String? contentType,
    required int? sizeBytes,
    required String? createdByUid,
    required DateTime createdAt,
    required DateTime? updatedAt,
  }) {
    return <String, dynamic>{
      'mediaId': mediaId,
      'dogId': dogId,
      'dogKey': dogKey,
      'sessionId': sessionId,
      'kind': kind.name,
      'storagePath': storagePath,
      'thumbnailStoragePath': thumbnailStoragePath,
      'contentType': contentType,
      'sizeBytes': sizeBytes,
      'status': DogMediaStatus.active.name,
      'createdByUid': createdByUid,
      'createdAt': Timestamp.fromDate(createdAt.toUtc()),
      'updatedAt': Timestamp.fromDate((updatedAt ?? createdAt).toUtc()),
      'deletedAt': null,
      'source': 'mobile',
    }..removeWhere((key, value) => value == null && key != 'deletedAt');
  }

  static String _joinStoragePath(Iterable<String> segments) {
    return segments
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .join('/');
  }
}
