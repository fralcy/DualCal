import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dual_cal/core/providers/event_provider.dart';
import 'package:dual_cal/core/utils/data_manager.dart';
import 'package:dual_cal/core/utils/lunar_calendar_service.dart';
import 'package:dual_cal/models/calendar_event.dart';

void main() {
  const lunarService = LunarCalendarService();
  late EventProvider provider;

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('dualcal_event_test_');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
    await DataManager().initialize(hivePath: dir.path);
  });

  setUp(() {
    provider = EventProvider();
  });

  test(
      'a lunar yearly-recurring event occurs on the same lunar day/month in later years',
      () async {
    await provider.addEvent(
      title: 'Giỗ',
      dateType: EventDateType.lunar,
      lunarDay: 10,
      lunarMonth: 3,
      lunarYear: 2023,
      recurrence: EventRecurrence.yearly,
    );

    final solar2024 = lunarService.lunarToSolar(10, 3, 2024)!;
    final solar2025 = lunarService.lunarToSolar(10, 3, 2025)!;

    expect(
      provider.eventsForDate(solar2024).map((e) => e.title),
      contains('Giỗ'),
    );
    expect(
      provider.eventsForDate(solar2025).map((e) => e.title),
      contains('Giỗ'),
    );
  });

  test('a lunar yearly event does not fire before its original anchor year',
      () async {
    await provider.addEvent(
      title: 'Future event',
      dateType: EventDateType.lunar,
      lunarDay: 5,
      lunarMonth: 5,
      lunarYear: 2025,
      recurrence: EventRecurrence.yearly,
    );

    final solar2024 = lunarService.lunarToSolar(5, 5, 2024)!;
    expect(
      provider.eventsForDate(solar2024).map((e) => e.title),
      isNot(contains('Future event')),
    );
  });

  test('a solar one-time event only occurs on its exact date', () async {
    final created = await provider.addEvent(
      title: 'Meeting',
      dateType: EventDateType.solar,
      solarDate: DateTime(2026, 5, 20),
    );

    expect(
      provider.eventsForDate(DateTime(2026, 5, 20)).map((e) => e.id),
      contains(created.id),
    );
    expect(provider.eventsForDate(DateTime(2027, 5, 20)), isEmpty);
  });

  test('a solar yearly-recurring event fires every year on the same month/day',
      () async {
    await provider.addEvent(
      title: 'Birthday',
      dateType: EventDateType.solar,
      solarDate: DateTime(2020, 12, 25),
      recurrence: EventRecurrence.yearly,
    );

    expect(
      provider.eventsForDate(DateTime(2026, 12, 25)).map((e) => e.title),
      contains('Birthday'),
    );
    expect(provider.eventsForDate(DateTime(2019, 12, 25)), isEmpty);
  });

  test('deleteEvent removes it from future queries', () async {
    final created = await provider.addEvent(
      title: 'To delete',
      dateType: EventDateType.solar,
      solarDate: DateTime(2026, 3, 3),
    );
    await provider.deleteEvent(created.id);

    expect(provider.eventsForDate(DateTime(2026, 3, 3)), isEmpty);
  });
}
