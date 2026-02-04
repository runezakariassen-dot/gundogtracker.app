import 'dart:io';

/// Pure Dart resolver used in `dart test -p vm` (no Flutter engine, no plugins).
Future<Directory> resolveBaseSupportDir() async {
  // Keep it stable and writable across platforms/CI.
  final dir = Directory(pJoin(Directory.systemTemp.path, 'jakthund_support'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

/// Tiny local join helper to avoid importing package:path in this file.
String pJoin(String a, String b) {
  if (a.endsWith(Platform.pathSeparator)) return '$a$b';
  return '$a${Platform.pathSeparator}$b';
}
