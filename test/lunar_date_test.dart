import 'package:flutter_test/flutter_test.dart';

import 'package:dual_cal/core/models/lunar_date.dart';

void main() {
  group('canChiForYear matches known reference years', () {
    final knownYears = <int, String>{
      1984: 'Giáp Tý',
      2020: 'Canh Tý',
      2023: 'Quý Mão',
      2024: 'Giáp Thìn',
      2025: 'Ất Tỵ',
    };

    knownYears.forEach((year, expected) {
      test('$year is $expected', () {
        expect(canChiForYear(year), expected);
      });
    });
  });

  test('the cycle repeats every 60 years', () {
    expect(canChiForYear(1984), canChiForYear(1984 + 60));
    expect(canChiForYear(2024), canChiForYear(2024 - 60));
  });

  test('LunarDate.canChi delegates to canChiForYear', () {
    const date = LunarDate(day: 10, month: 3, year: 2024);
    expect(date.canChi, 'Giáp Thìn');
  });

  group('canChiEnglishForYear renders element + Vietnamese-zodiac animal', () {
    final knownYears = <int, String>{
      1984: 'Wood Rat',
      2020: 'Metal Rat',
      2023: 'Water Cat', // Quý Mão — Vietnamese zodiac uses Cat, not Rabbit
      2024: 'Wood Dragon',
      2025: 'Wood Snake',
      // Sửu (Ox in Chinese zodiac) is Buffalo in the Vietnamese 12 con giáp.
      2021: 'Metal Buffalo', // Tân Sửu
    };

    knownYears.forEach((year, expected) {
      test('$year is $expected', () {
        expect(canChiEnglishForYear(year), expected);
      });
    });
  });

  test('LunarDate.canChiEnglish delegates to canChiEnglishForYear', () {
    const date = LunarDate(day: 10, month: 3, year: 2024);
    expect(date.canChiEnglish, 'Wood Dragon');
  });

  test('allCanChiNamesVi has all 60 distinct names, in cycle order', () {
    expect(allCanChiNamesVi, hasLength(60));
    expect(allCanChiNamesVi.toSet(), hasLength(60));
    expect(allCanChiNamesVi[0], 'Giáp Tý');
    expect(allCanChiNamesVi.indexOf('Giáp Thìn'), 40);
  });

  test('allCanChiNamesEnglish matches allCanChiNamesVi position-for-position',
      () {
    expect(allCanChiNamesEnglish, hasLength(60));
    expect(allCanChiNamesEnglish[0], 'Wood Rat');
    expect(allCanChiNamesEnglish[40], 'Wood Dragon');
  });

  test('canChiCycleIndex agrees with allCanChiNamesVi for known years', () {
    expect(canChiCycleIndex(1984), 0);
    expect(canChiCycleIndex(2024), 40);
    expect(allCanChiNamesVi[canChiCycleIndex(2024)], canChiForYear(2024));
  });

  test('canChiCycleIndex is stable across a 60-year cycle', () {
    expect(canChiCycleIndex(2024), canChiCycleIndex(2024 - 60));
    expect(canChiCycleIndex(2024), canChiCycleIndex(2024 + 60));
  });
}
