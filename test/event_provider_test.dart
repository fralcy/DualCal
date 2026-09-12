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

  test('a solar weekly-recurring event fires on the same weekday every week',
      () async {
    await provider.addEvent(
      title: 'Standup',
      dateType: EventDateType.solar,
      solarDate: DateTime(2026, 1, 5), // a Monday
      recurrence: EventRecurrence.weekly,
    );

    expect(
      provider.eventsForDate(DateTime(2026, 1, 12)).map((e) => e.title),
      contains('Standup'),
    );
    expect(provider.eventsForDate(DateTime(2026, 1, 6)), isEmpty);
    expect(provider.eventsForDate(DateTime(2025, 12, 29)), isEmpty);
  });

  test('a solar monthly-recurring event fires on the same day every month',
      () async {
    await provider.addEvent(
      title: 'Rent',
      dateType: EventDateType.solar,
      solarDate: DateTime(2026, 1, 15),
      recurrence: EventRecurrence.monthly,
    );

    expect(
      provider.eventsForDate(DateTime(2026, 4, 15)).map((e) => e.title),
      contains('Rent'),
    );
    expect(provider.eventsForDate(DateTime(2026, 4, 16)), isEmpty);
    expect(provider.eventsForDate(DateTime(2025, 12, 15)), isEmpty);
  });

  test(
      'a solar quarterly-recurring event fires every 3 months, not every month',
      () async {
    await provider.addEvent(
      title: 'Quarterly review',
      dateType: EventDateType.solar,
      solarDate: DateTime(2026, 1, 10),
      recurrence: EventRecurrence.quarterly,
    );

    expect(
      provider.eventsForDate(DateTime(2026, 4, 10)).map((e) => e.title),
      contains('Quarterly review'),
    );
    expect(provider.eventsForDate(DateTime(2026, 2, 10)), isEmpty);
    expect(provider.eventsForDate(DateTime(2026, 3, 10)), isEmpty);
  });

  test(
      'a lunar monthly-recurring event anchored on the last day of its month '
      'keeps landing on the last day of later months regardless of 29 vs 30 days',
      () async {
    final daysInMonth3 = lunarService.daysInLunarMonth(2024, 3);
    final anchorSolar = lunarService.lunarToSolar(daysInMonth3, 3, 2024)!;

    await provider.addEvent(
      title: 'Rằm cuối tháng',
      dateType: EventDateType.lunar,
      lunarDay: daysInMonth3,
      lunarMonth: 3,
      lunarYear: 2024,
      recurrence: EventRecurrence.monthly,
    );

    final laterMonthStart = lunarService
        .startOfNextLunarMonth(lunarService.startOfNextLunarMonth(anchorSolar));
    final laterLunar = lunarService.solarToLunar(laterMonthStart);
    final daysInLaterMonth = lunarService.daysInLunarMonth(
      laterLunar.year,
      laterLunar.month,
      isLeapMonth: laterLunar.isLeapMonth,
    );
    final expectedOccurrence = lunarService.lunarToSolar(
      daysInLaterMonth,
      laterLunar.month,
      laterLunar.year,
      isLeapMonth: laterLunar.isLeapMonth,
    )!;

    expect(
      provider.eventsForDate(expectedOccurrence).map((e) => e.title),
      contains('Rằm cuối tháng'),
    );
  });
}
