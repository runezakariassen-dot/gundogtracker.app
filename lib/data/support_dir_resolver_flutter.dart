import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Flutter runtime resolver (uses path_provider).
Future<Directory> resolveBaseSupportDir() async {
  return getApplicationSupportDirectory();
}
