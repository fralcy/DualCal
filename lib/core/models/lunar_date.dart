const _canChiStems = [
  'Giáp',
  'Ất',
  'Bính',
  'Đinh',
  'Mậu',
  'Kỷ',
  'Canh',
  'Tân',
  'Nhâm',
  'Quý',
];

const _canChiBranches = [
  'Tý',
  'Sửu',
  'Dần',
  'Mão',
  'Thìn',
  'Tỵ',
  'Ngọ',
  'Mùi',
  'Thân',
  'Dậu',
  'Tuất',
  'Hợi',
];

// English rendering doesn't transliterate the Can Chi names — it shows the
// stem's five-element (ngũ hành) and the branch's zodiac animal instead
// (e.g. "Giáp Thìn" -> "Wood Dragon"), which is how these years are
// conventionally described in English. The animal names follow the
// Vietnamese 12 con giáp specifically (Sửu = Buffalo, Mão = Cat), not the
// Chinese zodiac (Ox, Rabbit), since that's the calendar this app models.
const _stemElementsEn = [
  'Wood',
  'Wood',
  'Fire',
  'Fire',
  'Earth',
  'Earth',
  'Metal',
  'Metal',
  'Water',
  'Water',
];

const _branchAnimalsEn = [
  'Rat',
  'Buffalo',
  'Tiger',
  'Cat',
  'Dragon',
  'Snake',
  'Horse',
  'Goat',
  'Monkey',
  'Rooster',
  'Dog',
  'Pig',
];

int _mod(int a, int b) => ((a % b) + b) % b;

/// The Vietnamese sexagenary (Can Chi) name for a lunar year, e.g. 2024 ->
/// "Giáp Thìn". The cycle repeats every 60 years, so the plain year number
/// still disambiguates which cycle and is what leap-year math is based on
/// — Can Chi is purely a display label derived from it.
String canChiForYear(int year) {
  final stem = _canChiStems[_mod(year - 4, 10)];
  final branch = _canChiBranches[_mod(year - 4, 12)];
  return '$stem $branch';
}

/// The English rendering of a lunar year's Can Chi, e.g. 2024 -> "Wood
/// Dragon" (see [_stemElementsEn]/[_branchAnimalsEn] for why this isn't a
/// transliteration of [canChiForYear]).
String canChiEnglishForYear(int year) {
  final element = _stemElementsEn[_mod(year - 4, 10)];
  final animal = _branchAnimalsEn[_mod(year - 4, 12)];
  return '$element $animal';
}

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

  /// The Can Chi (sexagenary cycle) name for [year], e.g. "Giáp Thìn".
  String get canChi => canChiForYear(year);

  /// The English rendering of [canChi], e.g. "Wood Dragon".
  String get canChiEnglish => canChiEnglishForYear(year);

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
