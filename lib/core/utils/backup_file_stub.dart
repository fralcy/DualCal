/// Fallback selected when neither `dart.library.io` nor `dart.library.js`
/// applies. Flutter always has one of the two, so this exists only to
/// keep the conditional export exhaustive.
Future<String?> saveBackupFile(String fileName, String contents) async =>
    null;

Future<String?> pickAndReadBackupFile() async => null;
