import 'dart:math' as math;

import '../../core/models/lunar_date.dart';

/// Pure-Dart Vietnamese lunar calendar conversion.
///
/// Ported from Hồ Ngọc Đức's algorithm
/// (http://www.informatik.uni-leipzig.de/~duc/amlich/). No BuildContext, no
/// third-party package dependency — trivially unit-testable against known
/// reference dates (e.g. Tết of past years).
///
/// All Julian-day-number arithmetic uses integer division (`~/`) to avoid
/// floating-point drift. All new-moon/sun-longitude astronomical
/// computations are pinned to Vietnam's fixed **UTC+7** offset — never the
/// device's local timezone — because a user travelling abroad must not
/// change how their Vietnamese lunar dates are computed.
class LunarCalendarService {
  const LunarCalendarService();

  static const double _vnTimeZone = 7.0;

  // ---------------------------------------------------------------------
  // Julian day number <-> Gregorian date (integer-only arithmetic)
  // ---------------------------------------------------------------------

  static int jdFromDate(int dd, int mm, int yy) {
    final a = (14 - mm) ~/ 12;
    final y = yy + 4800 - a;
    final m = mm + 12 * a - 3;
    var jd = dd +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
    if (jd < 2299161) {
      jd = dd + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - 32083;
    }
    return jd;
  }

  static List<int> jdToDate(int jd) {
    int a, b, c;
    if (jd > 2299160) {
      a = jd + 32044;
      b = (4 * a + 3) ~/ 146097;
      c = a - (b * 146097) ~/ 4;
    } else {
      b = 0;
      c = jd + 32082;
    }
    final d = (4 * c + 3) ~/ 1461;
    final e = c - (1461 * d) ~/ 4;
    final m = (5 * e + 2) ~/ 153;
    final day = e - (153 * m + 2) ~/ 5 + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final year = b * 100 + d - 4800 + m ~/ 10;
    return [day, month, year];
  }

  // ---------------------------------------------------------------------
  // Astronomical helpers (double precision is inherent to the algorithm;
  // every result is floored back to an integer day before use).
  // ---------------------------------------------------------------------

  static double _newMoon(int k) {
    final t = k / 1236.85;
    final t2 = t * t;
    final t3 = t2 * t;
    final dr = math.pi / 180;
    var jd1 =
        2415020.75933 + 29.53058868 * k + 0.0001178 * t2 - 0.000000155 * t3;
    jd1 += 0.00033 * math.sin((166.56 + 132.87 * t - 0.009173 * t2) * dr);
    final m = 359.2242 + 29.10535608 * k - 0.0000333 * t2 - 0.00000347 * t3;
    final mpr =
        306.0253 + 385.81691806 * k + 0.0107306 * t2 + 0.00001236 * t3;
    final f = 21.2964 + 390.67050646 * k - 0.0016528 * t2 - 0.00000239 * t3;
    var c1 =
        (0.1734 - 0.000393 * t) * math.sin(m * dr) + 0.0021 * math.sin(2 * dr * m);
    c1 = c1 -
        0.4068 * math.sin(mpr * dr) +
        0.0161 * math.sin(dr * 2 * mpr) -
        0.0004 * math.sin(dr * 3 * mpr);
    c1 = c1 +
        0.0104 * math.sin(dr * 2 * f) -
        0.0051 * math.sin(dr * (m + mpr));
    c1 = c1 -
        0.0074 * math.sin(dr * (m - mpr)) +
        0.0004 * math.sin(dr * (2 * f + m));
    c1 = c1 -
        0.0004 * math.sin(dr * (2 * f - m)) -
        0.0006 * math.sin(dr * (2 * f + mpr));
    c1 = c1 +
        0.0010 * math.sin(dr * (2 * f - mpr)) +
        0.0005 * math.sin(dr * (2 * mpr + m));
    double deltaT;
    if (t < -11) {
      deltaT = 0.001 +
          0.000839 * t +
          0.0002261 * t2 -
          0.00000845 * t3 -
          0.000000081 * t * t3;
    } else {
      deltaT = -0.000278 + 0.000265 * t + 0.000262 * t2;
    }
    return jd1 + c1 - deltaT;
  }

  static double _sunLongitude(double jdn) {
    final t = (jdn - 2451545.0) / 36525;
    final t2 = t * t;
    final dr = math.pi / 180;
    final m = 357.52910 + 35999.05030 * t - 0.0001559 * t2 - 0.00000048 * t * t2;
    final l0 = 280.46645 + 36000.76983 * t + 0.0003032 * t2;
    var dl = (1.914600 - 0.004817 * t - 0.000014 * t2) * math.sin(dr * m);
    dl += (0.019993 - 0.000101 * t) * math.sin(dr * 2 * m) +
        0.000290 * math.sin(dr * 3 * m);
    var l = (l0 + dl) * dr;
    l -= math.pi * 2 * (l / (math.pi * 2)).floor();
    return l;
  }

  static int _getSunLongitude(int dayNumber, double timeZone) {
    return (_sunLongitude(dayNumber - 0.5 - timeZone / 24) / math.pi * 6)
        .floor();
  }

  static int _getNewMoonDay(int k, double timeZone) {
    return (_newMoon(k) + 0.5 + timeZone / 24).floor();
  }

  static int _getLunarMonth11(int yy, double timeZone) {
    final off = jdFromDate(31, 12, yy) - 2415021;
    final k = (off / 29.530588853).floor();
    var nm = _getNewMoonDay(k, timeZone);
    final sunLong = _getSunLongitude(nm, timeZone);
    if (sunLong >= 9) {
      nm = _getNewMoonDay(k - 1, timeZone);
    }
    return nm;
  }

  static int _getLeapMonthOffset(int a11, double timeZone) {
    final k = ((a11 - 2415021.076998695) / 29.530588853 + 0.5).floor();
    var last = 0;
    var i = 1;
    var arc = _getSunLongitude(_getNewMoonDay(k + i, timeZone), timeZone);
    do {
      last = arc;
      i++;
      arc = _getSunLongitude(_getNewMoonDay(k + i, timeZone), timeZone);
    } while (arc != last && i < 14);
    return i - 1;
  }

  /// Julian day number of the new moon that starts lunar month [lunarMonth]
  /// of [lunarYear] (1-based calendar month, 11/12 belong to the *previous*
  /// solar-year boundary per the algorithm). Returns null if [isLeapMonth]
  /// is requested but [lunarYear] has no leap occurrence of that month.
  int? _kForLunarMonth(int lunarMonth, int lunarYear, bool isLeapMonth) {
    int a11, b11;
    if (lunarMonth < 11) {
      a11 = _getLunarMonth11(lunarYear - 1, _vnTimeZone);
      b11 = _getLunarMonth11(lunarYear, _vnTimeZone);
    } else {
      a11 = _getLunarMonth11(lunarYear, _vnTimeZone);
      b11 = _getLunarMonth11(lunarYear + 1, _vnTimeZone);
    }
    var off = lunarMonth - 11;
    if (off < 0) off += 12;
    if (b11 - a11 > 365) {
      final leapOff = _getLeapMonthOffset(a11, _vnTimeZone);
      var leapMonth = leapOff - 2;
      if (leapMonth < 0) leapMonth += 12;
      if (isLeapMonth && lunarMonth != leapMonth) {
        return null;
      } else if (isLeapMonth || off >= leapOff) {
        off += 1;
      }
    } else if (isLeapMonth) {
      // This lunar year has no leap month at all.
      return null;
    }
    return (0.5 + (a11 - 2415021.076998695) / 29.530588853).floor() + off;
  }

  // ---------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------

  /// Converts a solar (Gregorian) date to its Vietnamese lunar equivalent.
  LunarDate solarToLunar(DateTime solarDate) {
    final dd = solarDate.day, mm = solarDate.month, yy = solarDate.year;
    final dayNumber = jdFromDate(dd, mm, yy);
    final k = ((dayNumber - 2415021.076998695) / 29.530588853).floor();
    var monthStart = _getNewMoonDay(k + 1, _vnTimeZone);
    if (monthStart > dayNumber) {
      monthStart = _getNewMoonDay(k, _vnTimeZone);
    }
    var a11 = _getLunarMonth11(yy, _vnTimeZone);
    var b11 = a11;
    int lunarYear;
    if (a11 >= monthStart) {
      lunarYear = yy;
      a11 = _getLunarMonth11(yy - 1, _vnTimeZone);
    } else {
      lunarYear = yy + 1;
      b11 = _getLunarMonth11(yy + 1, _vnTimeZone);
    }
    final lunarDay = dayNumber - monthStart + 1;
    final diff = ((monthStart - a11) / 29).floor();
    var lunarLeap = false;
    var lunarMonth = diff + 11;
    if (b11 - a11 > 365) {
      final leapMonthDiff = _getLeapMonthOffset(a11, _vnTimeZone);
      if (diff >= leapMonthDiff) {
        lunarMonth = diff + 10;
        if (diff == leapMonthDiff) {
          lunarLeap = true;
        }
      }
    }
    if (lunarMonth > 12) {
      lunarMonth -= 12;
    }
    if (lunarMonth >= 11 && diff < 4) {
      lunarYear -= 1;
    }
    return LunarDate(
      day: lunarDay,
      month: lunarMonth,
      year: lunarYear,
      isLeapMonth: lunarLeap,
    );
  }

  /// Converts a Vietnamese lunar date back to its solar (Gregorian)
  /// equivalent. Returns null if [isLeapMonth] is true but [lunarYear] has
  /// no leap occurrence of [lunarMonth].
  DateTime? lunarToSolar(
    int lunarDay,
    int lunarMonth,
    int lunarYear, {
    bool isLeapMonth = false,
  }) {
    final k = _kForLunarMonth(lunarMonth, lunarYear, isLeapMonth);
    if (k == null) return null;
    final monthStart = _getNewMoonDay(k, _vnTimeZone);
    final ymd = jdToDate(monthStart + lunarDay - 1);
    return DateTime(ymd[2], ymd[1], ymd[0]);
  }

  /// The calendar month number (1-12) that is leap in [lunarYear], or 0 if
  /// that year has no leap month.
  int getLeapMonthOfYear(int lunarYear) {
    final a11 = _getLunarMonth11(lunarYear - 1, _vnTimeZone);
    final b11 = _getLunarMonth11(lunarYear, _vnTimeZone);
    if (b11 - a11 <= 365) return 0;
    final leapOff = _getLeapMonthOffset(a11, _vnTimeZone);
    var leapMonth = leapOff - 2;
    if (leapMonth < 0) leapMonth += 12;
    if (leapMonth == 0) leapMonth = 12;
    return leapMonth;
  }

  bool isLeapMonthInYear(int lunarYear, int lunarMonth) =>
      getLeapMonthOfYear(lunarYear) == lunarMonth;

  /// Number of days (29 or 30) in the given lunar month, for date-picker
  /// bounds. Falls back to 30 for an invalid (year, month, isLeapMonth)
  /// combination rather than throwing, since callers use this only to size
  /// a picker.
  int daysInLunarMonth(
    int lunarYear,
    int lunarMonth, {
    bool isLeapMonth = false,
  }) {
    final k = _kForLunarMonth(lunarMonth, lunarYear, isLeapMonth);
    if (k == null) return 30;
    final start = _getNewMoonDay(k, _vnTimeZone);
    final end = _getNewMoonDay(k + 1, _vnTimeZone);
    return end - start;
  }

  /// Next solar-date occurrence of a yearly-recurring event anchored to
  /// lunar [lunarDay]/[lunarMonth], on or after [fromDate].
  ///
  /// App-wide convention: a lunar-anchored recurring event always resolves
  /// against the **non-leap** occurrence of its month, regardless of
  /// whether the event was originally created during a leap month — this
  /// keeps the reminder firing every single year instead of only on years
  /// that happen to have a leap month matching the original one.
  DateTime getNextLunarYearlyOccurrence(
    int lunarDay,
    int lunarMonth,
    DateTime fromDate,
  ) {
    final fromLunarYear = solarToLunar(fromDate).year;
    final fromDay = DateTime(fromDate.year, fromDate.month, fromDate.day);
    for (var i = 0; i < 3; i++) {
      final candidate =
          lunarToSolar(lunarDay, lunarMonth, fromLunarYear + i);
      if (candidate != null && !candidate.isBefore(fromDay)) {
        return candidate;
      }
    }
    return lunarToSolar(lunarDay, lunarMonth, fromLunarYear + 3) ?? fromDay;
  }

  /// Whether lunar [day] is the last day of its month (day 29 in a 29-day
  /// month, day 30 in a 30-day one). Used to detect a "last day of the
  /// month" anchor so a monthly-recurring event created on it keeps
  /// landing on the last day of every later month, not a fixed day number
  /// that may not exist in a shorter one.
  bool isEndOfLunarMonth(
    int day,
    int month,
    int year, {
    bool isLeapMonth = false,
  }) {
    return day == daysInLunarMonth(year, month, isLeapMonth: isLeapMonth);
  }

  /// Solar date of day 1 of the lunar month immediately following the one
  /// [solarDate] falls in — steps forward exactly one lunar month
  /// (including a leap month, if that's what comes next) with no
  /// probing/guessing.
  DateTime startOfNextLunarMonth(DateTime solarDate) {
    final lunar = solarToLunar(solarDate);
    final daysInMonth = daysInLunarMonth(
      lunar.year,
      lunar.month,
      isLeapMonth: lunar.isLeapMonth,
    );
    return solarDate.add(Duration(days: daysInMonth - lunar.day + 1));
  }

  /// Resolves a monthly-recurring lunar anchor — day [anchorDay], or the
  /// last day of the month when [anchorIsEndOfMonth] — to its occurrence
  /// within whichever lunar month [forDate] happens to fall in. Used to
  /// walk a monthly recurrence forward one lunar month (regular or leap)
  /// at a time via [startOfNextLunarMonth].
  DateTime? lunarMonthlyOccurrenceFor(
    DateTime forDate, {
    required int anchorDay,
    required bool anchorIsEndOfMonth,
  }) {
    final forLunar = solarToLunar(forDate);
    final daysInThisMonth = daysInLunarMonth(
      forLunar.year,
      forLunar.month,
      isLeapMonth: forLunar.isLeapMonth,
    );
    final targetDay = anchorIsEndOfMonth
        ? daysInThisMonth
        : (anchorDay > daysInThisMonth ? daysInThisMonth : anchorDay);
    return lunarToSolar(
      targetDay,
      forLunar.month,
      forLunar.year,
      isLeapMonth: forLunar.isLeapMonth,
    );
  }
}
