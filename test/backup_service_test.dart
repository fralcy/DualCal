import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dual_cal/core/utils/backup_service.dart';
import 'package:dual_cal/core/utils/data_manager.dart';
import 'package:dual_cal/models/app_settings.dart';
import 'package:dual_cal/models/calendar_event.dart';

void main() {
  late BackupService backupService;

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('dualcal_backup_test_');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
    // Each test gets its own fresh DataManager-backed Hive box by pointing
    // a brand-new DataManager instance-equivalent at a fresh temp dir —
    // DataManager is a singleton, so re-initializing mid-suite would be a
    // no-op; instead each test file/isolate gets exactly one initialize()
    // call and we clear state between tests via clearAll().
    if (!_initialized) {
      await DataManager().initialize(hivePath: dir.path);
      _initialized = true;
    } else {
      await DataManager().clearAll();
    }
    backupService = BackupService();
  });

  Future<CalendarEvent> addSampleEvent(String id, String title) async {
    final event = CalendarEvent.create(
      id: id,
      title: title,
      dateType: EventDateType.solar,
      solarDate: DateTime(2026, 5, 20),
    );
    await DataManager().saveEvent(event);
    return event;
  }

  test('export then import round-trips events and settings', () async {
    await addSampleEvent('e1', 'Meeting');
    await addSampleEvent('e2', 'Giỗ');
    await DataManager().saveSettings(
      AppSettings(
        languageCode: 'en',
        themeId: 'mint',
        defaultReminderDaysBefore: [2, 5],
      ),
    );

    final json = backupService.exportToJson();
    await DataManager().clearAll();
    expect(DataManager().getAllEvents(), isEmpty);

    final result = await backupService.importFromJson(json, merge: false);

    expect(result.eventCount, 2);
    expect(DataManager().getAllEvents().map((e) => e.title).toSet(),
        {'Meeting', 'Giỗ'});
    expect(DataManager().settings.languageCode, 'en');
    expect(DataManager().settings.themeId, 'mint');
    expect(DataManager().settings.defaultReminderDaysBefore, [2, 5]);
  });

  test('merge import keeps existing events not present in the backup',
      () async {
    await addSampleEvent('keep', 'Kept event');
    final json = backupService.exportToJson(); // backup has only "keep"

    await addSampleEvent('new', 'New event'); // added after the backup was taken

    final result = await backupService.importFromJson(json, merge: true);

    expect(result.eventCount, 2);
    expect(DataManager().getAllEvents().map((e) => e.id).toSet(),
        {'keep', 'new'});
  });

  test('replace import removes events not present in the backup', () async {
    await addSampleEvent('keep', 'Kept event');
    final json = backupService.exportToJson();

    await addSampleEvent('gone', 'Should be removed');

    final result = await backupService.importFromJson(json, merge: false);

    expect(result.eventCount, 1);
    expect(DataManager().getAllEvents().map((e) => e.id), ['keep']);
  });

  test('rejects a backup with a newer schema version than this app knows',
      () async {
    const futureJson = '{"schemaVersion": 999, "events": []}';
    expect(
      () => backupService.importFromJson(futureJson, merge: true),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('rejects malformed JSON', () async {
    expect(
      () => backupService.importFromJson('not json at all', merge: true),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('rejects a JSON object missing the events list', () async {
    expect(
      () => backupService.importFromJson('{"schemaVersion": 1}', merge: true),
      throwsA(isA<BackupFormatException>()),
    );
  });
}

bool _initialized = false;
