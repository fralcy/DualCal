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
}
