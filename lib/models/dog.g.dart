// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dog.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DogAdapter extends TypeAdapter<Dog> {
  @override
  final int typeId = 2;

  @override
  Dog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Dog(
      id: fields[4] as String?,
      name: fields[0] == null ? 'Ukjent' : fields[0] as String,
      dogKey: fields[5] == null ? '' : fields[5] as String,
      regNrDisplay: fields[6] == null ? '' : fields[6] as String,
      imagePath: fields[1] as String?,
      birthDate: fields[2] as DateTime?,
      pedigreeUrl: fields[3] as String?,
      breed: fields[7] as String?,
      ownerUserId: fields[8] as String?,
      ownerEmail: fields[18] as String?,
      title: fields[19] as String?,
      updatedAt: fields[9] as DateTime?,
      regNr: fields[10] as String?,
      achievedMilestones: fields[11] == null
          ? []
          : (fields[11] as List?)?.cast<AchievedMilestone>(),
      sex: fields[12] == null ? DogSex.male : fields[12] as DogSex?,
      watermarkShowTitle:
          fields[20] == null ? true : fields[20] as bool,
      watermarkShowName:
          fields[21] == null ? true : fields[21] as bool,
      deceasedAt: fields[13] as DateTime?,
      memorialNote: fields[14] as String?,
      profileHeroTextAnchor:
          fields[15] == null ? 'bottomLeft' : fields[15] as String,
      profileHeroTextScale: fields[16] == null ? 1.0 : fields[16] as double,
      nickname: fields[17] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Dog obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.birthDate)
      ..writeByte(3)
      ..write(obj.pedigreeUrl)
      ..writeByte(4)
      ..write(obj.id)
      ..writeByte(5)
      ..write(obj.dogKey)
      ..writeByte(6)
      ..write(obj.regNrDisplay)
      ..writeByte(7)
      ..write(obj.breed)
      ..writeByte(8)
      ..write(obj.ownerUserId)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.regNr)
      ..writeByte(11)
      ..write(obj.achievedMilestones)
      ..writeByte(12)
      ..write(obj.sex)
      ..writeByte(13)
      ..write(obj.deceasedAt)
      ..writeByte(14)
      ..write(obj.memorialNote)
      ..writeByte(15)
      ..write(obj.profileHeroTextAnchor)
      ..writeByte(16)
      ..write(obj.profileHeroTextScale)
      ..writeByte(17)
      ..write(obj.nickname)
      ..writeByte(18)
      ..write(obj.ownerEmail)
      ..writeByte(19)
      ..write(obj.title)
      ..writeByte(20)
      ..write(obj.watermarkShowTitle)
      ..writeByte(21)
      ..write(obj.watermarkShowName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
