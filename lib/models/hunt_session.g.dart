// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hunt_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HuntSessionAdapter extends TypeAdapter<HuntSession> {
  @override
  final int typeId = 1;

  @override
  HuntSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final dateTime = fields[1] as DateTime;
    return HuntSession(
      dogId: fields[0] as String,
      dogKey: fields[13] as String?,
      dateTime: dateTime,
      location: fields[2] as String,
      durationMinutes: fields[3] as int,
      birdsSeen: fields[4] as int,
      points: fields[5] as int,
      flushes: fields[6] as int,
      notes: fields[7] as String,
      secondaryPoints: fields[12] as int?,
      trackKey: fields[8] as int?,
      trackId: fields[9] as String?,
      birdSpecies: (fields[10] as List?)?.cast<String>(),
      mediaPaths: (fields[11] as List?)?.cast<String>(),
      createdByUserId: fields[14] as String?,
      sessionType: fields[15] as SessionType?,
      birdsShotCount: fields[16] as int?,
      birdsShotSpecies: fields[17] as String?,
      updatedAt: fields[18] as DateTime? ?? dateTime,
      deletedAt: fields[19] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, HuntSession obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.dogId)
      ..writeByte(13)
      ..write(obj.dogKey)
      ..writeByte(1)
      ..write(obj.dateTime)
      ..writeByte(2)
      ..write(obj.location)
      ..writeByte(3)
      ..write(obj.durationMinutes)
      ..writeByte(4)
      ..write(obj.birdsSeen)
      ..writeByte(5)
      ..write(obj.points)
      ..writeByte(6)
      ..write(obj.flushes)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(12)
      ..write(obj.secondaryPoints)
      ..writeByte(8)
      ..write(obj.trackKey)
      ..writeByte(9)
      ..write(obj.trackId)
      ..writeByte(10)
      ..write(obj.birdSpecies)
      ..writeByte(11)
      ..write(obj.mediaPaths)
      ..writeByte(14)
      ..write(obj.createdByUserId)
      ..writeByte(15)
      ..write(obj.sessionType)
      ..writeByte(16)
      ..write(obj.birdsShotCount)
      ..writeByte(17)
      ..write(obj.birdsShotSpecies)
      ..writeByte(18)
      ..write(obj.updatedAt)
      ..writeByte(19)
      ..write(obj.deletedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HuntSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
