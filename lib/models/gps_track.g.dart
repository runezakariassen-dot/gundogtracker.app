// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gps_track.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GpsTrackAdapter extends TypeAdapter<GpsTrack> {
  @override
  final int typeId = 4;

  @override
  GpsTrack read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GpsTrack(
      dogId: fields[0] as String,
      startTime: fields[1] as DateTime,
      endTime: fields[2] as DateTime,
      points: (fields[3] as List).cast<GpsPoint>(),
    );
  }

  @override
  void write(BinaryWriter writer, GpsTrack obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.dogId)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.points);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GpsTrackAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
