import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dual_cal/core/models/upcoming_reminder.dart';
import 'package:dual_cal/core/providers/event_provider.dart';
import 'package:dual_cal/core/providers/notification_provider.dart';
import 'package:dual_cal/core/utils/data_manager.dart';
import 'package:dual_cal/core/utils/lunar_calendar_service.dart';
import 'package:dual_cal/core/utils/notification_service_base.dart';
import 'package:dual_cal/models/calendar_event.dart';

/// Records every scheduleForEvent/cancelForEvent call instead of touching
/// any real platform channel, so this test suite works identically on
/// every host regardless of `dart.library.io`/`dart.library.js`.
class _FakeNotificationService implements NotificationServiceBase {
  final Map<String, List<DateTime>> scheduled = {};
  final List<String> cancelled = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> scheduleForEvent(
    CalendarEvent event,
    List<DateTime> occurrenceDates,
  ) async {
    scheduled[event.id] = occurrenceDates;
  }

  @override
  Future<void> cancelForEvent(String eventId) async {
    cancelled.add(eventId);
    scheduled.remove(eventId);
  }

  @override
  List<UpcomingReminder> get upcomingReminders => const [];
}

void main() {
  const lunarService = LunarCalendarService();
  late EventProvider eventProvider;
  late _FakeNotificationService fakeService;
  late NotificationProvider notificationProvider;

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('dualcal_notif_test_');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
    await DataManager().initialize(hivePath: dir.path);
  });

  setUp(() {
    eventProvider = EventProvider();
    fakeService = _FakeNotificationService();
    notificationProvider = NotificationProvider(
      eventProvider: eventProvider,
      notificationService: fakeService,
    );
  });

  tearDown(() => notificationProvider.dispose());

  test('adding a solar one-time future event schedules exactly one occurrence',
      () async {
    final future = DateTime.now().add(const Duration(days: 10));
    final created = await eventProvider.addEvent(
      title: 'Meeting',
      dateType: EventDateType.solar,
      solarDate: future,
      reminderDaysBefore: [1],
    );
    await notificationProvider.rescheduleAll();

    final dates = fakeService.scheduled[created.id];
    expect(dates, isNotNull);
    expect(dates!.length, 1);
    expect(
      dates.first,
      DateTime(future.year, future.month, future.day),
    );
  });

  test('a solar one-time event already in the past is not scheduled',
      () async {
    final past = DateTime.now().subtract(const Duration(days: 5));
    final created = await eventProvider.addEvent(
      title: 'Old meeting',
      dateType: EventDateType.solar,
      solarDate: past,
    );
    await notificationProvider.rescheduleAll();

    expect(fakeService.scheduled.containsKey(created.id), isFalse);
  });

  test(
      'a yearly-recurring lunar event schedules multiple future occurrences, '
      'always on the non-leap month', () async {
    final created = await eventProvider.addEvent(
      title: 'Giỗ',
      dateType: EventDateType.lunar,
      lunarDay: 10,
      lunarMonth: 3,
      lunarYear: 2020,
      recurrence: EventRecurrence.yearly,
      reminderDaysBefore: [1],
    );
    await notificationProvider.rescheduleAll();

    final dates = fakeService.scheduled[created.id];
    expect(dates, isNotNull);
    expect(dates!.length, greaterThanOrEqualTo(1));
    for (final d in dates) {
      final lunar = lunarService.solarToLunar(d);
      expect(lunar.isLeapMonth, isFalse);
      expect(lunar.day, 10);
      expect(lunar.month, 3);
    }
  });

  test('a solar weekly event schedules 8 upcoming occurrences a week apart',
      () async {
    final anchor = DateTime.now().subtract(const Duration(days: 100));
    final anchorDay = DateTime(anchor.year, anchor.month, anchor.day);
    final created = await eventProvider.addEvent(
      title: 'Standup',
      dateType: EventDateType.solar,
      solarDate: anchorDay,
      recurrence: EventRecurrence.weekly,
      reminderDaysBefore: [0],
    );
    await notificationProvider.rescheduleAll();

    final dates = fakeService.scheduled[created.id];
    expect(dates, isNotNull);
    expect(dates!.length, 8);
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    for (final d in dates) {
      expect(d.weekday, anchorDay.weekday);
      expect(d.isBefore(todayMidnight), isFalse);
    }
    for (var i = 1; i < dates.length; i++) {
      expect(dates[i].difference(dates[i - 1]).inDays, 7);
    }
  });

  test('a solar monthly event schedules 6 upcoming occurrences a month apart',
      () async {
    final anchor = DateTime.now().subtract(const Duration(days: 400));
    final anchorDay = DateTime(anchor.year, anchor.month, anchor.day);
    final created = await eventProvider.addEvent(
      title: 'Rent',
      dateType: EventDateType.solar,
      solarDate: anchorDay,
      recurrence: EventRecurrence.monthly,
      reminderDaysBefore: [0],
    );
    await notificationProvider.rescheduleAll();

    final dates = fakeService.scheduled[created.id];
    expect(dates, isNotNull);
    expect(dates!.length, 6);
    for (final d in dates) {
      expect(d.day, anchorDay.day);
    }
  });

  test('a solar quarterly event schedules 4 occurrences 3 months apart',
      () async {
    final anchor = DateTime.now().subtract(const Duration(days: 400));
    final anchorDay = DateTime(anchor.year, anchor.month, anchor.day);
    final created = await eventProvider.addEvent(
      title: 'Quarterly review',
      dateType: EventDateType.solar,
      solarDate: anchorDay,
      recurrence: EventRecurrence.quarterly,
      reminderDaysBefore: [0],
    );
    await notificationProvider.rescheduleAll();

    final dates = fakeService.scheduled[created.id];
    expect(dates, isNotNull);
    expect(dates!.length, 4);
    for (var i = 1; i < dates.length; i++) {
      final monthsDiff = (dates[i].year - dates[i - 1].year) * 12 +
          (dates[i].month - dates[i - 1].month);
      expect(monthsDiff, 3);
    }
  });

  test(
      'a lunar monthly event anchored on its month\'s last day schedules '
      'occurrences always on the last day of their own lunar month',
      () async {
    final daysInMonth3 = lunarService.daysInLunarMonth(2024, 3);
    final created = await eventProvider.addEvent(
      title: 'Rằm cuối tháng',
      dateType: EventDateType.lunar,
      lunarDay: daysInMonth3,
      lunarMonth: 3,
      lunarYear: 2024,
      recurrence: EventRecurrence.monthly,
      reminderDaysBefore: [0],
    );
    await notificationProvider.rescheduleAll();

    final dates = fakeService.scheduled[created.id];
    expect(dates, isNotNull);
    expect(dates!.isNotEmpty, isTrue);
    for (final d in dates) {
      final lunar = lunarService.solarToLunar(d);
      final daysInThatMonth = lunarService.daysInLunarMonth(
        lunar.year,
        lunar.month,
        isLeapMonth: lunar.isLeapMonth,
      );
      expect(lunar.day, daysInThatMonth);
    }
  });

  test('deleting an event cancels its scheduled reminders', () async {
    final future = DateTime.now().add(const Duration(days: 20));
    final created = await eventProvider.addEvent(
      title: 'To cancel',
      dateType: EventDateType.solar,
      solarDate: future,
    );
    await notificationProvider.rescheduleAll();
    expect(fakeService.scheduled.containsKey(created.id), isTrue);

    await eventProvider.deleteEvent(created.id);
    // EventProvider.deleteEvent -> notifyListeners -> NotificationProvider
    // auto-reschedules via its own listener (fire-and-forget), so pump the
    // event queue to let that async work finish before asserting.
    await pumpEventQueue();

    expect(fakeService.scheduled.containsKey(created.id), isFalse);
  });
}
