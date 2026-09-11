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
    required this.name,
    required this.dateType,
    required this.month,
    required this.day,
    required this.isDayOff,
    required this.scope,
  });

  final String id;

  /// Plain display name. Will become an l10n key lookup once the rest of
  /// the app's UI text is localized (Milestone 7) — kept as a literal for
  /// now to match every other screen's current hardcoded-string
  /// convention.
  final String name;

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
    name: 'Tết Dương lịch',
    dateType: HolidayDateType.solar,
    month: 1,
    day: 1,
    isDayOff: true,
    scope: HolidayScope.vietnam,
  ),
  HolidayDefinition(
    id: 'vn_liberation_day',
    name: 'Ngày Giải phóng miền Nam',
    dateType: HolidayDateType.solar,
    month: 4,
    day: 30,
    isDayOff: true,
    scope: HolidayScope.vietnam,
  ),
  HolidayDefinition(
    id: 'vn_labor_day',
    name: 'Quốc tế Lao động',
    dateType: HolidayDateType.solar,
    month: 5,
    day: 1,
    isDayOff: true,
    scope: HolidayScope.vietnam,
  ),
  HolidayDefinition(
    id: 'vn_national_day',
    name: 'Quốc khánh',
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
    name: 'Mùng 1 Tết',
    dateType: HolidayDateType.lunar,
    month: 1,
    day: 1,
    isDayOff: true,
    scope: HolidayScope.vietnam,
  ),
  HolidayDefinition(
    id: 'vn_tet_day2',
    name: 'Mùng 2 Tết',
    dateType: HolidayDateType.lunar,
    month: 1,
    day: 2,
    isDayOff: true,
    scope: HolidayScope.vietnam,
  ),
  HolidayDefinition(
    id: 'vn_tet_day3',
    name: 'Mùng 3 Tết',
    dateType: HolidayDateType.lunar,
    month: 1,
    day: 3,
    isDayOff: true,
    scope: HolidayScope.vietnam,
  ),
  HolidayDefinition(
    id: 'vn_hung_kings',
    name: 'Giỗ Tổ Hùng Vương',
    dateType: HolidayDateType.lunar,
    month: 3,
    day: 10,
    isDayOff: true,
    scope: HolidayScope.vietnam,
  ),

  // --- Vietnamese observances (not an official day off) ---
  HolidayDefinition(
    id: 'vn_lantern_festival',
    name: 'Rằm tháng Giêng',
    dateType: HolidayDateType.lunar,
    month: 1,
    day: 15,
    isDayOff: false,
    scope: HolidayScope.vietnam,
  ),
  HolidayDefinition(
    id: 'vn_vu_lan',
    name: 'Lễ Vu Lan',
    dateType: HolidayDateType.lunar,
    month: 7,
    day: 15,
    isDayOff: false,
    scope: HolidayScope.vietnam,
  ),
  HolidayDefinition(
    id: 'vn_mid_autumn',
    name: 'Tết Trung Thu',
    dateType: HolidayDateType.lunar,
    month: 8,
    day: 15,
    isDayOff: false,
    scope: HolidayScope.vietnam,
  ),
  HolidayDefinition(
    id: 'vn_womens_day',
    name: 'Ngày Phụ nữ Việt Nam',
    dateType: HolidayDateType.solar,
    month: 10,
    day: 20,
    isDayOff: false,
    scope: HolidayScope.vietnam,
  ),
  HolidayDefinition(
    id: 'vn_teachers_day',
    name: 'Ngày Nhà giáo Việt Nam',
    dateType: HolidayDateType.solar,
    month: 11,
    day: 20,
    isDayOff: false,
    scope: HolidayScope.vietnam,
  ),

  // --- Major international observances (not a day off in Vietnam) ---
  HolidayDefinition(
    id: 'intl_valentines',
    name: 'Lễ Tình nhân',
    dateType: HolidayDateType.solar,
    month: 2,
    day: 14,
    isDayOff: false,
    scope: HolidayScope.international,
  ),
  HolidayDefinition(
    id: 'intl_womens_day',
    name: 'Quốc tế Phụ nữ',
    dateType: HolidayDateType.solar,
    month: 3,
    day: 8,
    isDayOff: false,
    scope: HolidayScope.international,
  ),
  HolidayDefinition(
    id: 'intl_childrens_day',
    name: 'Quốc tế Thiếu nhi',
    dateType: HolidayDateType.solar,
    month: 6,
    day: 1,
    isDayOff: false,
    scope: HolidayScope.international,
  ),
  HolidayDefinition(
    id: 'intl_halloween',
    name: 'Halloween',
    dateType: HolidayDateType.solar,
    month: 10,
    day: 31,
    isDayOff: false,
    scope: HolidayScope.international,
  ),
  HolidayDefinition(
    id: 'intl_christmas',
    name: 'Giáng sinh',
    dateType: HolidayDateType.solar,
    month: 12,
    day: 25,
    isDayOff: false,
    scope: HolidayScope.international,
  ),
];
