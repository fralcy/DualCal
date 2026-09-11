/// A Vietnamese lunar calendar date, as produced by
/// `LunarCalendarService.solarToLunar`. Not Hive-persisted — always derived
/// on demand from a solar date.
class LunarDate {
  final int day;
  final int month;
  final int year;
  final bool isLeapMonth;

  const LunarDate({
    required this.day,
    required this.month,
    required this.year,
    this.isLeapMonth = false,
  });

  @override
  String toString() =>
      'LunarDate($day/$month${isLeapMonth ? " nhuận" : ""}/$year)';

  @override
  bool operator ==(Object other) =>
      other is LunarDate &&
      other.day == day &&
      other.month == month &&
      other.year == year &&
      other.isLeapMonth == isLeapMonth;

  @override
  int get hashCode => Object.hash(day, month, year, isLeapMonth);
}
