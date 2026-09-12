import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../models/calendar_event.dart';
import '../utils/data_manager.dart';
import '../utils/lunar_calendar_service.dart';

/// CRUD over [CalendarEvent] via [DataManager], plus recurrence expansion so
/// callers can just ask "what happens on this date" without re-deriving
/// solar/lunar recurrence rules themselves.
class EventProvider extends ChangeNotifier {
  EventProvider({DataManager? dataManager, LunarCalendarService? lunarService})
      : _dataManager = dataManager ?? DataManager(),
        _lunarService = lunarService ?? const LunarCalendarService() {
    _reload();
  }

  final DataManager _dataManager;
  final LunarCalendarService _lunarService;

  List<CalendarEvent> _events = [];
  List<CalendarEvent> get events => List.unmodifiable(_events);

  void _reload() {
    _events = _dataManager.getAllEvents();
  }

  /// Force-reload from [DataManager] — used after a backup import replaces
  /// or merges events wholesale.
  void refresh() {
    _reload();
    notifyListeners();
  }

  Future<CalendarEvent> addEvent({
    required String title,
    String? description,
    required EventDateType dateType,
    DateTime? solarDate,
    int? lunarDay,
    int? lunarMonth,
    int? lunarYear,
    bool isLeapMonth = false,
    EventRecurrence recurrence = EventRecurrence.none,
    List<int> reminderDaysBefore = const [],
    int colorTag = 0,
    String? category,
    int reminderHour = 8,
    int reminderMinute = 0,
  }) async {
    final event = CalendarEvent.create(
      id: const Uuid().v4(),
      title: title,
      description: description,
      dateType: dateType,
      solarDate: solarDate,
      lunarDay: lunarDay,
      lunarMonth: lunarMonth,
      lunarYear: lunarYear,
      isLeapMonth: isLeapMonth,
      recurrence: recurrence,
      reminderDaysBefore: reminderDaysBefore,
      colorTag: colorTag,
      category: category,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
    );
    await _dataManager.saveEvent(event);
    _reload();
    notifyListeners();
    return event;
  }

  Future<void> updateEvent(CalendarEvent updated) async {
    await _dataManager.saveEvent(updated);
    _reload();
    notifyListeners();
  }

  Future<void> deleteEvent(String id) async {
    await _dataManager.deleteEvent(id);
    _reload();
    notifyListeners();
  }

  /// All events that fall on [solarDate], resolving one-time vs
  /// yearly-recurring, solar-anchored vs lunar-anchored events.
  List<CalendarEvent> eventsForDate(DateTime solarDate) {
    final day = DateTime(solarDate.year, solarDate.month, solarDate.day);
    return _events.where((e) => _occursOn(e, day)).toList();
  }

  bool _occursOn(CalendarEvent event, DateTime day) {
    if (event.dateType == EventDateType.solar) {
      final anchor = event.solarDate;
      if (anchor == null) return false;
      final anchorDay = DateTime(anchor.year, anchor.month, anchor.day);
      switch (event.recurrence) {
        case EventRecurrence.yearly:
          return anchor.month == day.month &&
              anchor.day == day.day &&
              !day.isBefore(anchorDay);
        case EventRecurrence.weekly:
          return day.weekday == anchorDay.weekday && !day.isBefore(anchorDay);
        case EventRecurrence.monthly:
          return day.day == anchorDay.day && !day.isBefore(anchorDay);
        case EventRecurrence.quarterly:
          if (day.isBefore(anchorDay) || day.day != anchorDay.day) {
            return false;
          }
          final monthsDiff =
              (day.year - anchorDay.year) * 12 + (day.month - anchorDay.month);
          return monthsDiff % 3 == 0;
        case EventRecurrence.none:
          return anchorDay == day;
      }
    }

    final lunarDay = event.lunarDay;
    final lunarMonth = event.lunarMonth;
    if (lunarDay == null || lunarMonth == null) return false;
    final dayLunar = _lunarService.solarToLunar(day);
    final anchorYear = event.lunarYear;

    if (event.recurrence == EventRecurrence.yearly) {
      // App-wide convention: a lunar-anchored recurring event always
      // resolves against the non-leap occurrence of its month (see
      // LunarCalendarService.getNextLunarYearlyOccurrence).
      if (dayLunar.isLeapMonth) return false;
      if (dayLunar.day != lunarDay || dayLunar.month != lunarMonth) {
        return false;
      }
      if (anchorYear == null) return true;
      final anchorSolar = _lunarService.lunarToSolar(
        lunarDay,
        lunarMonth,
        anchorYear,
        isLeapMonth: false,
      );
      return anchorSolar == null || !day.isBefore(anchorSolar);
    }

    if (event.recurrence == EventRecurrence.monthly) {
      // Unlike yearly recurrence, a lunar monthly event is expected to also
      // fire during an inserted leap month (e.g. rằm/mùng một are still
      // observed then), so no leap filtering here.
      if (anchorYear == null) return false;
      final anchorSolar = _lunarService.lunarToSolar(
        lunarDay,
        lunarMonth,
        anchorYear,
        isLeapMonth: event.isLeapMonth,
      );
      if (anchorSolar == null || day.isBefore(anchorSolar)) return false;
      final anchorIsEndOfMonth = _lunarService.isEndOfLunarMonth(
        lunarDay,
        lunarMonth,
        anchorYear,
        isLeapMonth: event.isLeapMonth,
      );
      final occurrence = _lunarService.lunarMonthlyOccurrenceFor(
        day,
        anchorDay: lunarDay,
        anchorIsEndOfMonth: anchorIsEndOfMonth,
      );
      if (occurrence == null) return false;
      return DateTime(occurrence.year, occurrence.month, occurrence.day) ==
          day;
    }

    if (anchorYear == null) return false;
    return dayLunar.day == lunarDay &&
        dayLunar.month == lunarMonth &&
        dayLunar.year == anchorYear &&
        dayLunar.isLeapMonth == event.isLeapMonth;
  }
}
