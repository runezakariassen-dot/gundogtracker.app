import 'package:cloud_firestore/cloud_firestore.dart';

/// Minimal view of a Firestore users/{uid} document.
class AppUser {
  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.providerId,
    this.createdAt,
    this.lastLoginAt,
    required this.locale,
    required this.rolesAdmin,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String? providerId;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final String locale;
  final bool rolesAdmin;

  factory AppUser.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};

    return AppUser(
      uid: snapshot.id,
      email: _stringFrom(data['email']),
      displayName: _stringFrom(data['displayName']),
      photoURL: _stringFrom(data['photoURL']),
      providerId: _stringFrom(data['providerId']),
      createdAt: _timestampToDateTime(data['createdAt']),
      lastLoginAt: _timestampToDateTime(data['lastLoginAt']),
      locale: _stringFrom(data['locale']) ?? 'nb',
      rolesAdmin: _mapBoolFrom(data['roles'], 'admin'),
    );
  }

  static String? _stringFrom(dynamic value) =>
      value is String && value.isNotEmpty ? value : null;

  static DateTime? _timestampToDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  static bool _mapBoolFrom(dynamic value, String key) {
    if (value is Map<String, dynamic>) {
      final candidate = value[key];
      if (candidate is bool) {
        return candidate;
      }
    }
    return false;
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, displayName: $displayName, '
        'providerId: $providerId, locale: $locale, rolesAdmin: $rolesAdmin)';
  }
}
