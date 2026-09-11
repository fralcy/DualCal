import '../models/holiday_definition.dart';
import '../models/lunar_date.dart';
import 'lunar_calendar_service.dart';

/// New Year's Eve (Giao thừa) — the last day of the 12th lunar month, which
/// can be either the 29th or the 30th depending on the year. Resolved
/// dynamically as "the day before Mùng 1 Tết" rather than a fixed
/// day/month match, so it's never silently missed in a short (29-day)
/// year.
const _tetEve = HolidayDefinition(
  id: 'vn_tet_eve',
  nameKey: 'holidayTetEve',
  dateType: HolidayDateType.lunar,
  month: 12,
  day: 30,
  isDayOff: true,
  scope: HolidayScope.vietnam,
);

/// Resolves the static [defaultHolidays] table against real solar dates on
/// demand — no I/O, trivially testable. Lunar-anchored holidays always
/// match the non-leap occurrence of their month, consistent with the
/// app-wide recurring-event convention (`LunarCalendarService.
/// getNextLunarYearlyOccurrence`).
class HolidayService {
  const HolidayService({LunarCalendarService? lunarService})
      : _lunarService = lunarService ?? const LunarCalendarService();

  final LunarCalendarService _lunarService;

  List<HolidayDefinition> holidaysOnDate(DateTime date) {
    final matches = <HolidayDefinition>[];

    final nextDayLunar =
        _lunarService.solarToLunar(date.add(const Duration(days: 1)));
    if (!nextDayLunar.isLeapMonth &&
        nextDayLunar.day == 1 &&
        nextDayLunar.month == 1) {
      matches.add(_tetEve);
    }

    LunarDate? lunar;
    for (final def in defaultHolidays) {
      if (def.dateType == HolidayDateType.solar) {
        if (def.month == date.month && def.day == date.day) {
          matches.add(def);
        }
      } else {
        lunar ??= _lunarService.solarToLunar(date);
        if (!lunar.isLeapMonth &&
            lunar.month == def.month &&
            lunar.day == def.day) {
          matches.add(def);
        }
      }
    }
    return matches;
  }

  bool isDayOff(DateTime date) =>
      holidaysOnDate(date).any((h) => h.isDayOff);
}
