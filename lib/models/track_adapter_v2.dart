import 'package:hive/hive.dart';

import 'gps_point.dart';
import 'track.dart';

class TrackAdapterV2 extends TypeAdapter<Track> {
  @override
  final int typeId = 16;

  @override
  Track read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Track(
      id: fields[0] as String,
      createdAt: fields[1] as DateTime,
      source: fields[2] as String,
      points: (fields[3] as List).cast<GpsPoint>(),
    );
  }

  @override
  void write(BinaryWriter writer, Track obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.source)
      ..writeByte(3)
      ..write(obj.points);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackAdapterV2 &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
