import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

class GpxFilePayload {
  const GpxFilePayload({
    required this.xml,
    required this.fileName,
    required this.fileSizeBytes,
    this.path,
  });

  final String xml;
  final String fileName;
  final int fileSizeBytes;
  final String? path;
}

class GpxFileLoader {
  static bool _isPicking = false;

  static Future<GpxFilePayload?> pickAndLoadGpx() async {
    if (_isPicking) return null;
    _isPicking = true;
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['gpx'],
        withData: true,
      );
    } on PlatformException catch (_) {
      return null;
    } catch (_) {
      return null;
    } finally {
      _isPicking = false;
    }

    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.first;
    Uint8List? bytes = picked.bytes;

    if (bytes == null && picked.path != null) {
      bytes = await File(picked.path!).readAsBytes();
    }

    if (bytes == null) {
      throw const FormatException('Kunne ikke lese GPX-filen');
    }

    const maxBytes = 10 * 1024 * 1024;
    if (bytes.length > maxBytes) {
      throw FormatException(
          'GPX-filen er for stor (${bytes.length ~/ 1024} KB, maks 10 MB)');
    }

    try {
      return GpxFilePayload(
        xml: utf8.decode(bytes),
        fileName: picked.name,
        fileSizeBytes: bytes.length,
        path: picked.path,
      );
    } on FormatException {
      return GpxFilePayload(
        xml: latin1.decode(bytes),
        fileName: picked.name,
        fileSizeBytes: bytes.length,
        path: picked.path,
      );
    }
  }
}
