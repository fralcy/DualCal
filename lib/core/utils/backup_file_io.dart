import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Mobile (Android/iOS): `saveFile` requires bytes and writes directly via
/// the platform's share/save sheet — there's no filesystem path to write
/// to ourselves. Desktop (Windows/macOS/Linux): `saveFile` only returns a
/// chosen path; we write the file ourselves.
Future<String?> saveBackupFile(String fileName, String contents) async {
  if (Platform.isAndroid || Platform.isIOS) {
    final bytes = Uint8List.fromList(utf8.encode(contents));
    return FilePicker.platform.saveFile(fileName: fileName, bytes: bytes);
  }

  final path = await FilePicker.platform.saveFile(
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (path == null) return null;

  final resolvedPath =
      path.toLowerCase().endsWith('.json') ? path : '$path.json';
  await File(resolvedPath).writeAsString(contents);
  return resolvedPath;
}

Future<String?> pickAndReadBackupFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  final path = result?.files.single.path;
  if (path == null) return null;
  return File(path).readAsString();
}
