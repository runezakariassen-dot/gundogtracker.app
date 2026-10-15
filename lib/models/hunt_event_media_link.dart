import 'package:hive/hive.dart';

class HuntEventMediaLink {
  const HuntEventMediaLink({
    required this.id,
    required this.huntEventId,
    required this.mediaId,
    required this.createdAt,
    required this.sortOrder,
  });

  final String id;
  final String huntEventId;
  final String mediaId;
  final DateTime createdAt;
  final int sortOrder;
}

class HuntEventMediaLinkAdapter extends TypeAdapter<HuntEventMediaLink> {
  @override
  final int typeId = 53;

  @override
  HuntEventMediaLink read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (var index = 0; index < count; index++)
        reader.readByte(): reader.read(),
    };
    return HuntEventMediaLink(
      id: fields[0] as String,
      huntEventId: fields[1] as String,
      mediaId: fields[2] as String,
      createdAt: fields[3] as DateTime,
      sortOrder: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HuntEventMediaLink obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.huntEventId)
      ..writeByte(2)
      ..write(obj.mediaId)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.sortOrder);
  }
}
