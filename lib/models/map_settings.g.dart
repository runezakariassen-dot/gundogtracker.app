// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MapSettingsAdapter extends TypeAdapter<MapSettings> {
  @override
  final int typeId = 6;

  @override
  MapSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MapSettings(
      mode: fields[0] as String,
      offlineMbtilesPath: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MapSettings obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.mode)
      ..writeByte(1)
      ..write(obj.offlineMbtilesPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
