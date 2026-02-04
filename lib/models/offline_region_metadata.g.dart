// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_region_metadata.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineRegionMetadataAdapter extends TypeAdapter<OfflineRegionMetadata> {
  @override
  final int typeId = 14;

  @override
  OfflineRegionMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineRegionMetadata(
      id: fields[0] as String,
      name: fields[1] as String,
      createdAt: fields[2] as DateTime,
      minLat: fields[3] as double,
      minLon: fields[4] as double,
      maxLat: fields[5] as double,
      maxLon: fields[6] as double,
      minZoom: fields[7] as int,
      maxZoom: fields[8] as int,
      tileSourceKey: fields[9] as String,
      radiusKm: fields[10] as double?,
      storeName: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineRegionMetadata obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.minLat)
      ..writeByte(4)
      ..write(obj.minLon)
      ..writeByte(5)
      ..write(obj.maxLat)
      ..writeByte(6)
      ..write(obj.maxLon)
      ..writeByte(7)
      ..write(obj.minZoom)
      ..writeByte(8)
      ..write(obj.maxZoom)
      ..writeByte(9)
      ..write(obj.tileSourceKey)
      ..writeByte(10)
      ..write(obj.radiusKm)
      ..writeByte(11)
      ..write(obj.storeName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineRegionMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
