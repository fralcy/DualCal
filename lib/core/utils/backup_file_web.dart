import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:web/web.dart' as web;

/// Web has no filesystem path to hand back, and `file_picker`'s web
/// platform implementation doesn't actually implement `saveFile` (it only
/// implements `pickFiles` — calling `saveFile` throws `UnimplementedError`,
/// silently, since nothing here awaited/caught it before). Trigger the
/// download ourselves instead: a Blob + a detached `<a download>` element,
/// clicked programmatically — the standard way to save a file from a web
/// page without a picker dialog, landing in the browser's default
/// Downloads folder.
Future<String?> saveBackupFile(String fileName, String contents) async {
  final bytes = Uint8List.fromList(utf8.encode(contents));
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
  return fileName;
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
