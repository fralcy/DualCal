import 'package:flutter_test/flutter_test.dart';
import 'package:dual_cal/core/utils/lunar_calendar_service.dart';

void main() {
  final service = const LunarCalendarService();

  group('solarToLunar - known Tết (lunar New Year) dates', () {
    final knownTet = <DateTime, int>{
      DateTime(2020, 1, 25): 2020,
      DateTime(2021, 2, 12): 2021,
      DateTime(2022, 2, 1): 2022,
      DateTime(2023, 1, 22): 2023,
      DateTime(2024, 2, 10): 2024,
      DateTime(2025, 1, 29): 2025,
      DateTime(2026, 2, 17): 2026,
    };

    knownTet.forEach((solarDate, expectedLunarYear) {
      test('$solarDate is lunar 1/1/$expectedLunarYear', () {
        final lunar = service.solarToLunar(solarDate);
        expect(lunar.day, 1);
        expect(lunar.month, 1);
        expect(lunar.year, expectedLunarYear);
        expect(lunar.isLeapMonth, false);
      });
    });
  });

  test('lunarToSolar is the inverse of solarToLunar for Tết dates', () {
    final tet2024 = service.lunarToSolar(1, 1, 2024);
    expect(tet2024, DateTime(2024, 2, 10));
  });

  test('2023 has a leap 2nd lunar month (nhuận tháng 2)', () {
    expect(service.getLeapMonthOfYear(2023), 2);
    expect(service.isLeapMonthInYear(2023, 2), isTrue);
    expect(service.isLeapMonthInYear(2023, 3), isFalse);
  });

  test('a year with no leap month reports 0', () {
    expect(service.getLeapMonthOfYear(2024), 0);
  });

  test('lunarToSolar returns null for a non-existent leap month', () {
    final result =
        service.lunarToSolar(1, 5, 2024, isLeapMonth: true); // 2024 has no leap month
    expect(result, isNull);
  });

  test('daysInLunarMonth returns 29 or 30', () {
    final days = service.daysInLunarMonth(2024, 1);
    expect(days, anyOf(29, 30));
  });

  test('getNextLunarYearlyOccurrence resolves to the non-leap month even '
      'when queried from a date within a leap-month year', () {
    // Lunar 10/2 (non-leap), queried from just after Tết 2023 (which has a
    // leap 2nd month) — must land on the regular (non-leap) 2nd month.
    final next =
        service.getNextLunarYearlyOccurrence(10, 2, DateTime(2023, 1, 23));
    final backToLunar = service.solarToLunar(next);
    expect(backToLunar.day, 10);
    expect(backToLunar.month, 2);
    expect(backToLunar.isLeapMonth, false);
    expect(next.isBefore(DateTime(2023, 1, 23)), isFalse);
  });

  test('isEndOfLunarMonth recognizes the last day regardless of 29 vs 30',
      () {
    final days2024Month1 = service.daysInLunarMonth(2024, 1);
    expect(
      service.isEndOfLunarMonth(days2024Month1, 1, 2024),
      isTrue,
    );
    expect(
      service.isEndOfLunarMonth(days2024Month1 - 1, 1, 2024),
      isFalse,
    );
  });

  test('startOfNextLunarMonth lands exactly on lunar day 1 of the next month',
      () {
    final anchor = service.lunarToSolar(10, 3, 2024)!;
    final nextMonthStart = service.startOfNextLunarMonth(anchor);
    final nextLunar = service.solarToLunar(nextMonthStart);
    expect(nextLunar.day, 1);
    expect(nextLunar.month, 4);
    expect(nextLunar.year, 2024);
  });

  test(
      'lunarMonthlyOccurrenceFor keeps landing on the end of the month '
      'whether it has 29 or 30 days', () {
    // Find a lunar month anchored on its own last day, then confirm the
    // occurrence resolved for a date in a LATER month (which may have a
    // different length) is still that later month's last day.
    final daysInMonth3 = service.daysInLunarMonth(2024, 3);
    final anchorDate = service.lunarToSolar(daysInMonth3, 3, 2024)!;
    expect(service.isEndOfLunarMonth(daysInMonth3, 3, 2024), isTrue);

    final monthAfterNextStart = service
        .startOfNextLunarMonth(service.startOfNextLunarMonth(anchorDate));
    final occurrence = service.lunarMonthlyOccurrenceFor(
      monthAfterNextStart,
      anchorDay: daysInMonth3,
      anchorIsEndOfMonth: true,
    )!;
    final occurrenceLunar = service.solarToLunar(occurrence);
    final daysInThatMonth = service.daysInLunarMonth(
      occurrenceLunar.year,
      occurrenceLunar.month,
      isLeapMonth: occurrenceLunar.isLeapMonth,
    );
    expect(occurrenceLunar.day, daysInThatMonth);
  });

  test(
      'lunarMonthlyOccurrenceFor clamps a fixed day-30 anchor down in a '
      '29-day month instead of overflowing', () {
    // Pick a 29-day month to anchor on day 29 (its last day) without
    // marking it as an end-of-month anchor, then resolve for a later
    // month that might only have 29 days too — day 29 always exists
    // (every lunar month has at least 29 days), so this should never clamp
    // in practice, but a day-30 fixed anchor resolved against a 29-day
    // target month must clamp down to 29 rather than throw or overflow.
    final occurrence = service.lunarMonthlyOccurrenceFor(
      service.lunarToSolar(1, 6, 2024)!,
      anchorDay: 30,
      anchorIsEndOfMonth: false,
    )!;
    final occurrenceLunar = service.solarToLunar(occurrence);
    final daysInThatMonth = service.daysInLunarMonth(
      occurrenceLunar.year,
      occurrenceLunar.month,
      isLeapMonth: occurrenceLunar.isLeapMonth,
    );
    expect(occurrenceLunar.day, occurrenceLunar.day <= 30 ? occurrenceLunar.day : 30);
    expect(occurrenceLunar.day, daysInThatMonth < 30 ? daysInThatMonth : 30);
  });

  group('findRecentYearsFor', () {
    test('a normal (non-leap) day/month returns 3 consecutive years',
        () {
      final matches = service.findRecentYearsFor(
        10,
        3,
        startYear: 2024,
        count: 3,
      );
      expect(matches.map((m) => m.lunarYear), [2024, 2023, 2022]);
      for (final m in matches) {
        expect(m.solarDate, service.lunarToSolar(10, 3, m.lunarYear));
      }
    });

    test('a leap-month request matches the year known to have that leap month',
        () {
      // 2023 has a leap 2nd lunar month (see the leap-month test above).
      final matches = service.findRecentYearsFor(
        10,
        2,
        isLeapMonth: true,
        startYear: 2023,
        count: 1,
      );
      expect(matches, hasLength(1));
      expect(matches.single.lunarYear, 2023);
      expect(
        matches.single.solarDate,
        service.lunarToSolar(10, 2, 2023, isLeapMonth: true),
      );
    });

    test(
        'returns fewer than count (possibly empty) once maxYearsToSearch is '
        'exhausted, instead of looping forever', () {
      // Lunar day 31 never exists (every lunar month has at most 30 days),
      // so no year will ever match — this must terminate via the search
      // cap rather than hang.
      final matches = service.findRecentYearsFor(
        31,
        3,
        startYear: 2024,
        count: 3,
        maxYearsToSearch: 5,
      );
      expect(matches, isEmpty);
    });

    test('an effectively-impossible leap month returns empty within a small search cap',
        () {
      final matches = service.findRecentYearsFor(
        1,
        1,
        isLeapMonth: true,
        startYear: 2024,
        count: 1,
        maxYearsToSearch: 1,
      );
      expect(matches, isEmpty);
    });
  });

  group('findRecentYearsForCanChi', () {
    test('finds years exactly 60 years apart matching the given cycle index',
        () {
      // 2024 is Giáp Thìn, cycle index 40 (verified via canChiCycleIndex).
      final matches = service.findRecentYearsForCanChi(
        10,
        3,
        40,
        startYear: 2024,
        count: 3,
      );
      expect(matches.map((m) => m.lunarYear), [2024, 1964, 1904]);
      for (final m in matches) {
        expect(m.solarDate, service.lunarToSolar(10, 3, m.lunarYear));
      }
    });

    test('starts from the nearest matching year at or before startYear, '
        'even when startYear itself does not match', () {
      // 2023's cycle index is 39, one behind 2024's 40 — searching from
      // 2023 for index 40 should land on 1964 (2024 is *after* startYear).
      final matches = service.findRecentYearsForCanChi(
        10,
        3,
        40,
        startYear: 2023,
        count: 1,
      );
      expect(matches.single.lunarYear, 1964);
    });

    test('returns fewer than count once maxCyclesToSearch is exhausted', () {
      final matches = service.findRecentYearsForCanChi(
        31, // never a valid lunar day
        3,
        40,
        startYear: 2024,
        count: 3,
        maxCyclesToSearch: 2,
      );
      expect(matches, isEmpty);
    });
  });
}
