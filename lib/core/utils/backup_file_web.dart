import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Web has no filesystem path to hand back — `saveFile` triggers a browser
/// download directly from bytes, and picked files are only ever available
/// as in-memory bytes (no `path`).
Future<String?> saveBackupFile(String fileName, String contents) async {
  final bytes = Uint8List.fromList(utf8.encode(contents));
  return FilePicker.platform.saveFile(fileName: fileName, bytes: bytes);
}

Future<String?> pickAndReadBackupFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
    withData: true,
  );
  final bytes = result?.files.single.bytes;
  if (bytes == null) return null;
  return utf8.decode(bytes);
}
