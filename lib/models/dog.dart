// ignore_for_file: deprecated_member_use_from_same_package

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'package:jakthund_app/utils/json_encodable.dart';

import 'achieved_milestone.dart';
import 'dog_sex.dart';

part 'dog.g.dart';

enum ProfileHeroTextAnchor { bottomLeft, bottomCenter, topLeft }

ProfileHeroTextAnchor profileHeroTextAnchorFromValue(String? value) {
  if (value == null) return ProfileHeroTextAnchor.bottomLeft;
  return ProfileHeroTextAnchor.values.firstWhere(
    (anchor) => anchor.name == value,
    orElse: () => ProfileHeroTextAnchor.bottomLeft,
  );
}

extension ProfileHeroTextAnchorLabel on ProfileHeroTextAnchor {
  String get label {
    switch (this) {
      case ProfileHeroTextAnchor.bottomLeft:
        return 'Nederst til venstre';
      case ProfileHeroTextAnchor.bottomCenter:
        return 'Nederst midtstilt';
      case ProfileHeroTextAnchor.topLeft:
        return 'Øverst til venstre';
    }
  }
}

@HiveType(typeId: 2)
class Dog implements JsonEncodable {
  @HiveField(0, defaultValue: 'Ukjent')
  final String name;

  @HiveField(1)
  final String? imagePath; // lokal filsti til bilde

  @HiveField(2)
  final DateTime? birthDate;

  @HiveField(3)
  final String? pedigreeUrl;

  @HiveField(4)
  final String id;

  @HiveField(5, defaultValue: '')
  final String dogKey;

  @HiveField(6, defaultValue: '')
  final String regNrDisplay;

  @HiveField(7)
  final String? breed;

  @HiveField(8)
  final String? ownerUserId;

  @HiveField(9)
  final DateTime updatedAt;

  @HiveField(10)
  final String? regNr;

  @Deprecated('Use DogMilestoneState instead.')
  @HiveField(11, defaultValue: <AchievedMilestone>[])

  /// Legacy list kept for schema compatibility; do not write to this field.
  final List<AchievedMilestone> achievedMilestones;

  @HiveField(12, defaultValue: DogSex.male)
  final DogSex sex;

  @HiveField(13)
  final DateTime? deceasedAt;

  @HiveField(14)
  final String? memorialNote;

  @HiveField(15, defaultValue: 'bottomLeft')
  final String profileHeroTextAnchor;

  @HiveField(16, defaultValue: 1.0)
  final double profileHeroTextScale;

  @HiveField(17)
  final String? nickname;

  @HiveField(18)
  final String? ownerEmail;

  @HiveField(19)
  final String? title;

  @HiveField(20, defaultValue: true)
  final bool watermarkShowTitle;

  @HiveField(21, defaultValue: true)
  final bool watermarkShowName;

  @HiveField(22, defaultValue: true)
  final bool watermarkShowOfficialName;

  @HiveField(23, defaultValue: true)
  final bool watermarkShowNickname;

  @HiveField(24, defaultValue: false)
  final bool watermarkUseDarkText;

  @HiveField(25)
  final String? cloudId;

  @HiveField(26)
  final String? cloudOwnerUid;

  @HiveField(27)
  final DateTime? deletedAt;

  @HiveField(28)
  final String? memorialStory;

  static const Object _noValue = Object();

  Dog({
    String? id,
    required this.name,
    required this.dogKey,
    required this.regNrDisplay,
    this.imagePath,
    this.birthDate,
    this.pedigreeUrl,
    this.breed,
    this.ownerUserId,
    this.ownerEmail,
    this.title,
    DateTime? updatedAt,
    this.regNr,
    List<AchievedMilestone>? achievedMilestones,
    DogSex? sex,
    this.deceasedAt,
    this.memorialNote,
    this.memorialStory,
    this.profileHeroTextAnchor = 'bottomLeft',
    this.profileHeroTextScale = 1.0,
    this.nickname,
    this.watermarkShowTitle = true,
    this.watermarkShowName = true,
    this.watermarkShowOfficialName = true,
    this.watermarkShowNickname = true,
    this.watermarkUseDarkText = false,
    this.cloudId,
    this.cloudOwnerUid,
    this.deletedAt,
  })  : id = id ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime.now(),
        achievedMilestones = achievedMilestones ?? const [],
        sex = sex ?? DogSex.male;

  Dog copyWith({
    String? name,
    String? nickname,
    String? imagePath,
    DateTime? birthDate,
    String? pedigreeUrl,
    String? id,
    String? dogKey,
    String? regNrDisplay,
    String? breed,
    String? ownerUserId,
    String? ownerEmail,
    String? title,
    DateTime? updatedAt,
    String? regNr,
    List<AchievedMilestone>? achievedMilestones,
    DogSex? sex,
    bool? watermarkShowTitle,
    bool? watermarkShowName,
    bool? watermarkShowOfficialName,
    bool? watermarkShowNickname,
    bool? watermarkUseDarkText,
    Object? deceasedAt = _noValue,
    Object? memorialNote = _noValue,
    Object? memorialStory = _noValue,
    String? profileHeroTextAnchor,
    double? profileHeroTextScale,
    String? cloudId,
    String? cloudOwnerUid,
    Object? deletedAt = _noValue,
  }) {
    final DateTime? finalDeceasedAt = identical(deceasedAt, _noValue)
        ? this.deceasedAt
        : deceasedAt as DateTime?;
    final String? finalMemorialNote = identical(memorialNote, _noValue)
        ? this.memorialNote
        : memorialNote as String?;
    final String? finalMemorialStory = identical(memorialStory, _noValue)
        ? this.memorialStory
        : memorialStory as String?;
    final DateTime? finalDeletedAt = identical(deletedAt, _noValue)
        ? this.deletedAt
        : deletedAt as DateTime?;
    return Dog(
      name: name ?? this.name,
      dogKey: dogKey ?? this.dogKey,
      regNrDisplay: regNrDisplay ?? this.regNrDisplay,
      imagePath: imagePath ?? this.imagePath,
      birthDate: birthDate ?? this.birthDate,
      pedigreeUrl: pedigreeUrl ?? this.pedigreeUrl,
      breed: breed ?? this.breed,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      title: title ?? this.title,
      updatedAt: updatedAt ?? this.updatedAt,
      id: id ?? this.id,
      regNr: regNr ?? this.regNr,
      achievedMilestones: achievedMilestones ?? this.achievedMilestones,
      sex: sex ?? this.sex,
      watermarkShowTitle: watermarkShowTitle ?? this.watermarkShowTitle,
      watermarkShowName: watermarkShowName ?? this.watermarkShowName,
      watermarkShowOfficialName:
          watermarkShowOfficialName ?? this.watermarkShowOfficialName,
      watermarkShowNickname:
          watermarkShowNickname ?? this.watermarkShowNickname,
      watermarkUseDarkText: watermarkUseDarkText ?? this.watermarkUseDarkText,
      deceasedAt: finalDeceasedAt,
      memorialNote: finalMemorialNote,
      memorialStory: finalMemorialStory,
      profileHeroTextAnchor:
          profileHeroTextAnchor ?? this.profileHeroTextAnchor,
      profileHeroTextScale: profileHeroTextScale ?? this.profileHeroTextScale,
      nickname: nickname ?? this.nickname,
      cloudId: cloudId ?? this.cloudId,
      cloudOwnerUid: cloudOwnerUid ?? this.cloudOwnerUid,
      deletedAt: finalDeletedAt,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imagePath': imagePath,
      'birthDate': birthDate?.toIso8601String(),
      'pedigreeUrl': pedigreeUrl,
      'id': id,
      'dogKey': dogKey,
      'regNrDisplay': regNrDisplay,
      'breed': breed,
      'ownerUserId': ownerUserId,
      'ownerEmail': ownerEmail,
      'title': title,
      'watermarkShowTitle': watermarkShowTitle,
      'watermarkShowName': watermarkShowName,
      'watermarkShowOfficialName': watermarkShowOfficialName,
      'watermarkShowNickname': watermarkShowNickname,
      'watermarkUseDarkText': watermarkUseDarkText,
      'updatedAt': updatedAt.toIso8601String(),
      'regNr': regNr,
      'achievedMilestones':
          achievedMilestones.map((milestone) => milestone.toJson()).toList(),
      'sex': sex.name,
      'deceasedAt': deceasedAt?.toIso8601String(),
      'memorialNote': memorialNote,
      'memorialStory': memorialStory,
      'profileHeroTextAnchor': profileHeroTextAnchor,
      'profileHeroTextScale': profileHeroTextScale,
      'nickname': nickname,
      'cloudId': cloudId,
      'cloudOwnerUid': cloudOwnerUid,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  bool get isDeleted => deletedAt != null;

  String get displayName {
    final nick = nickname?.trim();
    if (nick != null && nick.isNotEmpty) return nick;
    final trimmed = name.trim();
    return trimmed.isNotEmpty ? trimmed : 'Uten navn';
  }
}
