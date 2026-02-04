import 'package:hive/hive.dart';

import 'session_type.dart';

class SessionTypeAdapter extends TypeAdapter<SessionType> {
  @override
  final int typeId = 17;

  @override
  SessionType read(BinaryReader reader) {
    final index = reader.readByte();
    return SessionType.values[index];
  }

  @override
  void write(BinaryWriter writer, SessionType obj) {
    writer.writeByte(obj.index);
  }
}
