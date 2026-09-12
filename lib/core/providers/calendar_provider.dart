import 'package:flutter/foundation.dart';

import '../models/lunar_date.dart';
import '../utils/lunar_calendar_service.dart';

/// View-state for the calendar screens: which month is visible, which day
/// is selected, and on-demand solar->lunar conversion for display. Holds no
/// persisted data — that's `EventProvider`/`DataManager`'s job.
class CalendarProvider extends ChangeNotifier {
  CalendarProvider({LunarCalendarService? lunarService})
      : _lunarService = lunarService ?? const LunarCalendarService() {
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  final LunarCalendarService _lunarService;

  late DateTime _visibleMonth; // always day == 1
  DateTime get visibleMonth => _visibleMonth;

  late DateTime _selectedDate;
  DateTime get selectedDate => _selectedDate;

  /// Direction of the most recent `visibleMonth` change: +1 moved forward,
  /// -1 moved backward, 0 for no meaningful direction (e.g. selecting a day
  /// in the same month). Lets a page-turn-style transition (see MonthGrid)
  /// know which way to slide.
  int _lastMonthDelta = 0;
  int get lastMonthDelta => _lastMonthDelta;

  LunarDate lunarDateFor(DateTime solarDate) =>
      _lunarService.solarToLunar(solarDate);

  void goToNextMonth() {
    _lastMonthDelta = 1;
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    _selectedDate = _clampSelectedDateToVisibleMonth();
    notifyListeners();
  }

  void goToPreviousMonth() {
    _lastMonthDelta = -1;
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    _selectedDate = _clampSelectedDateToVisibleMonth();
    notifyListeners();
  }

  /// Keeps the same day-of-month selected across a month change (e.g. the
  /// 15th stays selected when paging from March to April), clamped down for
  /// a shorter target month (the 31st in March becomes the 30th in April).
  DateTime _clampSelectedDateToVisibleMonth() {
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final day = _selectedDate.day.clamp(1, daysInMonth);
    return DateTime(_visibleMonth.year, _visibleMonth.month, day);
  }

  void goToToday() {
    final now = DateTime.now();
    final newVisibleMonth = DateTime(now.year, now.month);
    _lastMonthDelta = _monthDelta(_visibleMonth, newVisibleMonth);
    _visibleMonth = newVisibleMonth;
    _selectedDate = DateTime(now.year, now.month, now.day);
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    if (date.year != _visibleMonth.year || date.month != _visibleMonth.month) {
      final newVisibleMonth = DateTime(date.year, date.month);
      _lastMonthDelta = _monthDelta(_visibleMonth, newVisibleMonth);
      _visibleMonth = newVisibleMonth;
    }
    notifyListeners();
  }

  /// Sign of the month difference between [from] and [to] (-1, 0, or +1).
  int _monthDelta(DateTime from, DateTime to) {
    final diff = (to.year - from.year) * 12 + (to.month - from.month);
    return diff == 0 ? 0 : (diff > 0 ? 1 : -1);
  }

  /// Every solar date to render in the current month's grid, including the
  /// leading/trailing days borrowed from adjacent months to fill full
  /// weeks. [firstDayOfWeek] uses `DateTime.monday`..`DateTime.sunday`.
  List<DateTime> daysInGrid(int firstDayOfWeek) {
    final firstOfMonth = _visibleMonth;
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;

    final leading = (firstOfMonth.weekday - firstDayOfWeek + 7) % 7;
    final start = firstOfMonth.subtract(Duration(days: leading));

    final totalCells = ((leading + daysInMonth + 6) ~/ 7) * 7;
    return List.generate(totalCells, (i) => start.add(Duration(days: i)));
  }
}
