import 'package:flutter/foundation.dart';

import '../../models/calendar_event.dart';
import '../models/upcoming_reminder.dart';
import '../utils/lunar_calendar_service.dart';
import '../utils/notification_service.dart';
import '../utils/notification_service_base.dart';
import 'event_provider.dart';

/// Bridge between [EventProvider]'s event list and [NotificationService]:
/// whenever events change, resolves each event's next couple of years of
/// occurrences to concrete solar dates and (re)schedules its reminders.
/// Native OS recurrence only understands the solar calendar, so recurring
/// lunar-anchored events are pre-resolved here rather than scheduled as a
/// single "repeat yearly" alarm.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider({
    required EventProvider eventProvider,
    NotificationServiceBase? notificationService,
    LunarCalendarService? lunarService,
  })  : _eventProvider = eventProvider,
        _notificationService =
            notificationService ?? NotificationService.instance,
        _lunarService = lunarService ?? const LunarCalendarService() {
    _eventProvider.addListener(_onEventsChanged);
  }

  /// How many future occurrences to pre-schedule for a recurring event.
  static const _yearsAhead = 2;

  final EventProvider _eventProvider;
  final NotificationServiceBase _notificationService;
  final LunarCalendarService _lunarService;

  /// Event ids scheduled as of the last [rescheduleAll] call — needed to
  /// detect deletions, since a deleted event no longer appears in
  /// [EventProvider.events] at all and so would never otherwise get its
  /// stale reminders cancelled.
  Set<String> _lastKnownEventIds = {};

  Future<void> init() async {
    try {
      await _notificationService.init();
      await rescheduleAll();
    } catch (e, st) {
      // A notification/permission failure shouldn't stop the app from
      // running — the calendar and CRUD features work fine without it.
      debugPrint('NotificationProvider init failed: $e\n$st');
    }
  }

  void _onEventsChanged() {
    rescheduleAll();
  }

  Future<void> rescheduleAll() async {
    final currentIds = _eventProvider.events.map((e) => e.id).toSet();
    final removedIds = _lastKnownEventIds.difference(currentIds);
    for (final id in removedIds) {
      await _notificationService.cancelForEvent(id);
    }

    for (final event in _eventProvider.events) {
      await _scheduleEvent(event);
    }

    _lastKnownEventIds = currentIds;
    notifyListeners();
  }

  Future<void> _scheduleEvent(CalendarEvent event) async {
    final occurrences = _resolveOccurrences(event);
    if (occurrences.isEmpty) {
      await _notificationService.cancelForEvent(event.id);
      return;
    }
    await _notificationService.scheduleForEvent(event, occurrences);
  }

  /// Every solar date, from today onward, this event should fire a
  /// reminder set for — a single date for a one-time event, up to
  /// [_yearsAhead] dates for a yearly-recurring one.
  List<DateTime> _resolveOccurrences(CalendarEvent event) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (event.dateType == EventDateType.solar) {
      return _resolveSolarOccurrences(event, today);
    }
    return _resolveLunarOccurrences(event, today);
  }

  List<DateTime> _resolveSolarOccurrences(
    CalendarEvent event,
    DateTime today,
  ) {
    final anchor = event.solarDate;
    if (anchor == null) return [];
    final anchorDay = DateTime(anchor.year, anchor.month, anchor.day);

    if (event.recurrence == EventRecurrence.none) {
      return anchorDay.isBefore(today) ? [] : [anchorDay];
    }

    final occurrences = <DateTime>[];
    for (var i = 0; i <= _yearsAhead; i++) {
      DateTime candidate;
      try {
        candidate = DateTime(today.year + i, anchor.month, anchor.day);
      } catch (_) {
        continue; // e.g. Feb 29 in a non-leap year
      }
      if (!candidate.isBefore(today) && !candidate.isBefore(anchorDay)) {
        occurrences.add(candidate);
      }
    }
    return occurrences;
  }

  List<DateTime> _resolveLunarOccurrences(
    CalendarEvent event,
    DateTime today,
  ) {
    final lunarDay = event.lunarDay;
    final lunarMonth = event.lunarMonth;
    if (lunarDay == null || lunarMonth == null) return [];

    if (event.recurrence == EventRecurrence.none) {
      final anchorYear = event.lunarYear;
      if (anchorYear == null) return [];
      final solar = _lunarService.lunarToSolar(
        lunarDay,
        lunarMonth,
        anchorYear,
        isLeapMonth: event.isLeapMonth,
      );
      if (solar == null) return [];
      final day = DateTime(solar.year, solar.month, solar.day);
      return day.isBefore(today) ? [] : [day];
    }

    // Yearly lunar recurrence always resolves to the non-leap occurrence
    // (app-wide convention — see LunarCalendarService.
    // getNextLunarYearlyOccurrence).
    DateTime? anchorSolar;
    final anchorYear = event.lunarYear;
    if (anchorYear != null) {
      anchorSolar =
          _lunarService.lunarToSolar(lunarDay, lunarMonth, anchorYear);
    }

    final occurrences = <DateTime>[];
    var searchFrom = today;
    for (var i = 0; i <= _yearsAhead; i++) {
      final next = _lunarService.getNextLunarYearlyOccurrence(
        lunarDay,
        lunarMonth,
        searchFrom,
      );
      if (anchorSolar == null || !next.isBefore(anchorSolar)) {
        occurrences.add(next);
      }
      searchFrom = next.add(const Duration(days: 1));
    }
    return occurrences;
  }

  /// Populated on web only, for an in-app "upcoming reminders" list.
  List<UpcomingReminder> get upcomingReminders =>
      _notificationService.upcomingReminders;

  @override
  void dispose() {
    _eventProvider.removeListener(_onEventsChanged);
    super.dispose();
  }
}
