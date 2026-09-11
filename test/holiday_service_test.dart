import 'package:flutter_test/flutter_test.dart';

import 'package:dual_cal/core/utils/holiday_service.dart';
import 'package:dual_cal/core/utils/lunar_calendar_service.dart';

void main() {
  const service = HolidayService();
  const lunarService = LunarCalendarService();

  test('Jan 1st solar is Tết Dương lịch, a day off', () {
    final holidays = service.holidaysOnDate(DateTime(2026, 1, 1));
    expect(holidays.any((h) => h.id == 'vn_new_year' && h.isDayOff), isTrue);
  });

  test('the lunar New Year day is Mùng 1 Tết, a day off', () {
    // 2026-02-17 is lunar 1/1/2026 (see lunar_calendar_service_test.dart).
    final holidays = service.holidaysOnDate(DateTime(2026, 2, 17));
    expect(holidays.any((h) => h.id == 'vn_tet_day1' && h.isDayOff), isTrue);
  });

  test(
      'the day before Tết is Giao thừa, resolved dynamically regardless of '
      'a 29- or 30-day 12th lunar month', () {
    final holidays = service.holidaysOnDate(DateTime(2026, 2, 16));
    expect(holidays.any((h) => h.id == 'vn_tet_eve' && h.isDayOff), isTrue);
  });

  test('two days before Tết is not Giao thừa', () {
    final holidays = service.holidaysOnDate(DateTime(2026, 2, 15));
    expect(holidays.any((h) => h.id == 'vn_tet_eve'), isFalse);
  });

  test('a normal day has no holidays', () {
    expect(service.holidaysOnDate(DateTime(2026, 6, 15)), isEmpty);
  });

  test('Christmas is an international observance, not a day off', () {
    final holidays = service.holidaysOnDate(DateTime(2026, 12, 25));
    final christmas = holidays.firstWhere((h) => h.id == 'intl_christmas');
    expect(christmas.isDayOff, isFalse);
    expect(service.isDayOff(DateTime(2026, 12, 25)), isFalse);
  });

  test('Giỗ Tổ Hùng Vương matches lunar 10/3 every year', () {
    final solar2025 = lunarService.lunarToSolar(10, 3, 2025)!;
    final solar2026 = lunarService.lunarToSolar(10, 3, 2026)!;

    expect(
      service.holidaysOnDate(solar2025).any((h) => h.id == 'vn_hung_kings' && h.isDayOff),
      isTrue,
    );
    expect(
      service.holidaysOnDate(solar2026).any((h) => h.id == 'vn_hung_kings' && h.isDayOff),
      isTrue,
    );
  });
}
