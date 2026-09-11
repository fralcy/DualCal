enum HolidayDateType { solar, lunar }

enum HolidayScope { vietnam, international }

/// A recurring holiday/observance rendered on the calendar every year it
/// applies. Not Hive-persisted — ships as a static table and is resolved
/// against real dates on demand by `HolidayService`, since this is
/// read-only reference data that should update via app releases, not
/// user-mutable storage.
class HolidayDefinition {
  const HolidayDefinition({
    required this.id,
    required this.nameKey,
    required this.dateType,
    required this.month,
    required this.day,
    required this.isDayOff,
    required this.scope,
  });

  final String id;

  /// Key into `AppLocalizations` (see `holiday_l10n.dart`'s
  /// `resolveHolidayName`) — holiday names ship translated like every
  /// other piece of UI text, not hardcoded to one language.
  final String nameKey;

  final HolidayDateType dateType;

  /// 1-12. For [HolidayDateType.lunar] this is the lunar calendar month.
  final int month;

  /// Day of month (solar) or lunar day.
  final int day;

  /// Whether this is an official day off (Vietnamese public holiday) as
  /// opposed to an informational observance (e.g. Valentine's Day).
  final bool isDayOff;

  final HolidayScope scope;
}

const List<HolidayDefinition> defaultHolidays = [
  // --- Vietnamese public holidays (day off) ---
  HolidayDefinition(
    id: 'vn_new_year',
    nameKey: 'holidayNewYear',
    dateType: HolidayDateType.solar,
    month: 1,
    day: 1,
    isDayOff: true,
    scope: HolidayScope.vietnam,
  ),
  HolidayDefinition(
    id: 'vn_liberation_day',
    nameKey: 'holidayLiberationDay',
    dateType: HolidayDateType.solar,
    month: 4,
    day: 30,
    isDayOff: true,
    scope: HolidayScope.vietnam,
  ),
  HolidayDefinition(
    id: 'vn_labor_day',
    nameKey: 'holidayLaborDay',
    dateType: HolidayDateType.solar,
    month: 5,
    day: 1,
    isDayOff: true,
    scope: HolidayScope.vietnam,
  ),
  HolidayDefinition(
    id: 'vn_national_day',
    nameKey: 'holidayNationalDay',
    dateType: HolidayDateType.solar,
    month: 9,
    day: 2,
    isDayOff: true,
    scope: HolidayScope.vietnam,
  ),
  // Note: Giao thừa (New Year's Eve) is intentionally NOT listed here —
  // the 12th lunar month can have 29 or 30 days, so "the day before Tết"
  // is resolved dynamically in HolidayService instead of as a fixed
  // day-30 match, which would silently miss short (29-day) years.
  HolidayDefinition(
    id: 'vn_tet_day1',
    nameKey: 'holidayTetDay1',
    dateType: HolidayDateType.lunar,
    month: 1,
    day: 1,
    isDayOff: true,
    scope: HolidayScope.vietnam,
  ),
  HolidayDefinition(
    id: 'vn_tet_day2',
    nameKey: 'holidayTetDay2',
    dateType: HolidayDateType.lunar,
    month: 1,
    day: 2,
    isDayOff: true,
    scope: HolidayScope.vietnam,
  ),
  HolidayDefinition(
    id: 'vn_tet_day3',
    nameKey: 'holidayTetDay3',
    dateType: HolidayDateType.lunar,
    month: 1,
    day: 3,
    isDayOff: true,
    scope: HolidayScope.vietnam,
  ),
  HolidayDefinition(
    id: 'vn_hung_kings',
    nameKey: 'holidayHungKings',
    dateType: HolidayDateType.lunar,
    month: 3,
    day: 10,
    isDayOff: true,
    scope: HolidayScope.vietnam,
  ),

  // --- Vietnamese observances (not an official day off) ---
  HolidayDefinition(
    id: 'vn_lantern_festival',
    nameKey: 'holidayLanternFestival',
    dateType: HolidayDateType.lunar,
    month: 1,
    day: 15,
    isDayOff: false,
    scope: HolidayScope.vietnam,
  ),
  HolidayDefinition(
    id: 'vn_vu_lan',
    nameKey: 'holidayVuLan',
    dateType: HolidayDateType.lunar,
    month: 7,
    day: 15,
    isDayOff: false,
    scope: HolidayScope.vietnam,
  ),
  HolidayDefinition(
    id: 'vn_mid_autumn',
    nameKey: 'holidayMidAutumn',
    dateType: HolidayDateType.lunar,
    month: 8,
    day: 15,
    isDayOff: false,
    scope: HolidayScope.vietnam,
  ),
  HolidayDefinition(
    id: 'vn_womens_day',
    nameKey: 'holidayWomensDayVn',
    dateType: HolidayDateType.solar,
    month: 10,
    day: 20,
    isDayOff: false,
    scope: HolidayScope.vietnam,
  ),
  HolidayDefinition(
    id: 'vn_teachers_day',
    nameKey: 'holidayTeachersDay',
    dateType: HolidayDateType.solar,
    month: 11,
    day: 20,
    isDayOff: false,
    scope: HolidayScope.vietnam,
  ),

  // --- Major international observances (not a day off in Vietnam) ---
  HolidayDefinition(
    id: 'intl_valentines',
    nameKey: 'holidayValentines',
    dateType: HolidayDateType.solar,
    month: 2,
    day: 14,
    isDayOff: false,
    scope: HolidayScope.international,
  ),
  HolidayDefinition(
    id: 'intl_womens_day',
    nameKey: 'holidayWomensDayIntl',
    dateType: HolidayDateType.solar,
    month: 3,
    day: 8,
    isDayOff: false,
    scope: HolidayScope.international,
  ),
  HolidayDefinition(
    id: 'intl_childrens_day',
    nameKey: 'holidayChildrensDay',
    dateType: HolidayDateType.solar,
    month: 6,
    day: 1,
    isDayOff: false,
    scope: HolidayScope.international,
  ),
  HolidayDefinition(
    id: 'intl_halloween',
    nameKey: 'holidayHalloween',
    dateType: HolidayDateType.solar,
    month: 10,
    day: 31,
    isDayOff: false,
    scope: HolidayScope.international,
  ),
  HolidayDefinition(
    id: 'intl_christmas',
    nameKey: 'holidayChristmas',
    dateType: HolidayDateType.solar,
    month: 12,
    day: 25,
    isDayOff: false,
    scope: HolidayScope.international,
  ),
];
