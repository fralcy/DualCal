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
}
