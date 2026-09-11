import 'dart:convert';

import '../../models/app_settings.dart';
import '../../models/calendar_event.dart';
import 'data_manager.dart';

/// Result of a successful import: how many events ended up in the store
/// (merge mode: total after merging; replace mode: total after replacing).
class BackupImportResult {
  const BackupImportResult({required this.eventCount});
  final int eventCount;
}

/// Thrown when a backup file can't be parsed or its schema is newer than
/// this app understands.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);
  final String message;

  @override
  String toString() => 'BackupFormatException: $message';
}

/// Pure JSON (de)serialization of the app's backup format — no file I/O
/// here (see `backup_file.dart` for platform-specific save/pick), so this
/// is trivially unit-testable.
class BackupService {
  BackupService({DataManager? dataManager})
      : _dataManager = dataManager ?? DataManager();

  final DataManager _dataManager;

  /// Bump when the JSON shape changes in a way older app versions can't
  /// read; `importFromJson` rejects any file with a newer version than
  /// this.
  static const int schemaVersion = 1;

  String exportToJson() {
    final settings = _dataManager.settings;
    final events = _dataManager.getAllEvents();
    final map = <String, dynamic>{
      'schemaVersion': schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'appSettings': _settingsToJson(settings),
      'events': events.map(_eventToJson).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  /// Imports [jsonStr] into the store. [merge] upserts by event id and
  /// leaves existing events untouched; otherwise every existing event is
  /// replaced wholesale. Settings from the backup always overwrite current
  /// settings when present. Throws [BackupFormatException] on anything
  /// that isn't a valid, readable backup file.
  Future<BackupImportResult> importFromJson(
    String jsonStr, {
    required bool merge,
  }) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonStr);
    } on FormatException catch (e) {
      throw BackupFormatException('Invalid JSON: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const BackupFormatException('Backup file is not a JSON object');
    }

    final version = decoded['schemaVersion'];
    if (version is! int || version > schemaVersion) {
      throw BackupFormatException(
        'Unsupported backup schema version: $version',
      );
    }

    final eventsJson = decoded['events'];
    if (eventsJson is! List) {
      throw const BackupFormatException('Backup file has no "events" list');
    }
    final events = eventsJson
        .map((e) => _eventFromJson(e as Map<String, dynamic>))
        .toList();

    if (merge) {
      await _dataManager.mergeEvents(events);
    } else {
      await _dataManager.replaceAllEvents(events);
    }

    final settingsJson = decoded['appSettings'];
    if (settingsJson is Map<String, dynamic>) {
      await _dataManager.saveSettings(_settingsFromJson(settingsJson));
    }

    return BackupImportResult(eventCount: _dataManager.getAllEvents().length);
  }

  Map<String, dynamic> _settingsToJson(AppSettings s) => {
        'languageCode': s.languageCode,
        'themeId': s.themeId,
        'defaultReminderDaysBefore': s.defaultReminderDaysBefore,
        'firstDayOfWeek': s.firstDayOfWeek,
      };

  AppSettings _settingsFromJson(Map<String, dynamic> json) => AppSettings(
        languageCode: json['languageCode'] as String? ?? 'vi',
        themeId: json['themeId'] as String? ?? 'sky',
        defaultReminderDaysBefore:
            (json['defaultReminderDaysBefore'] as List<dynamic>?)
                    ?.map((e) => e as int)
                    .toList() ??
                const [1],
        firstDayOfWeek: json['firstDayOfWeek'] as int? ?? DateTime.monday,
      );

  Map<String, dynamic> _eventToJson(CalendarEvent e) => {
        'id': e.id,
        'title': e.title,
        'description': e.description,
        'dateType': e.dateType.name,
        'solarDate': e.solarDate?.toIso8601String(),
        'lunarDay': e.lunarDay,
        'lunarMonth': e.lunarMonth,
        'lunarYear': e.lunarYear,
        'isLeapMonth': e.isLeapMonth,
        'recurrence': e.recurrence.name,
        'reminderDaysBefore': e.reminderDaysBefore,
        'colorTag': e.colorTag,
        'category': e.category,
        'createdAt': e.createdAt.toIso8601String(),
        'updatedAt': e.updatedAt.toIso8601String(),
      };

  CalendarEvent _eventFromJson(Map<String, dynamic> json) {
    try {
      return CalendarEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        dateType: EventDateType.values.byName(json['dateType'] as String),
        solarDate: json['solarDate'] != null
            ? DateTime.parse(json['solarDate'] as String)
            : null,
        lunarDay: json['lunarDay'] as int?,
        lunarMonth: json['lunarMonth'] as int?,
        lunarYear: json['lunarYear'] as int?,
        isLeapMonth: json['isLeapMonth'] as bool? ?? false,
        recurrence: EventRecurrence.values
            .byName(json['recurrence'] as String? ?? 'none'),
        reminderDaysBefore: (json['reminderDaysBefore'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            const [],
        colorTag: json['colorTag'] as int? ?? 0,
        category: json['category'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );
    } on TypeError catch (e) {
      throw BackupFormatException('Malformed event entry: $e');
    } on ArgumentError catch (e) {
      throw BackupFormatException('Malformed event entry: $e');
    }
  }
}
