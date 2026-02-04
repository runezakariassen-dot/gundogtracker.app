// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dog_sex.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DogSexAdapter extends TypeAdapter<DogSex> {
  @override
  final int typeId = 222;

  @override
  DogSex read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DogSex.male;
      case 1:
        return DogSex.female;
      default:
        return DogSex.male;
    }
  }

  @override
  void write(BinaryWriter writer, DogSex obj) {
    switch (obj) {
      case DogSex.male:
        writer.writeByte(0);
        break;
      case DogSex.female:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DogSexAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
