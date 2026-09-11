import '../l10n/app_localizations.dart';
import '../models/holiday_definition.dart';

/// Resolves a [HolidayDefinition.nameKey] to its translated display name.
/// A plain switch rather than a Map, since ARB-generated getters aren't
/// first-class values that can be looked up by string key.
String resolveHolidayName(AppLocalizations l10n, String nameKey) {
  switch (nameKey) {
    case 'holidayNewYear':
      return l10n.holidayNewYear;
    case 'holidayLiberationDay':
      return l10n.holidayLiberationDay;
    case 'holidayLaborDay':
      return l10n.holidayLaborDay;
    case 'holidayNationalDay':
      return l10n.holidayNationalDay;
    case 'holidayTetEve':
      return l10n.holidayTetEve;
    case 'holidayTetDay1':
      return l10n.holidayTetDay1;
    case 'holidayTetDay2':
      return l10n.holidayTetDay2;
    case 'holidayTetDay3':
      return l10n.holidayTetDay3;
    case 'holidayHungKings':
      return l10n.holidayHungKings;
    case 'holidayLanternFestival':
      return l10n.holidayLanternFestival;
    case 'holidayVuLan':
      return l10n.holidayVuLan;
    case 'holidayMidAutumn':
      return l10n.holidayMidAutumn;
    case 'holidayWomensDayVn':
      return l10n.holidayWomensDayVn;
    case 'holidayTeachersDay':
      return l10n.holidayTeachersDay;
    case 'holidayValentines':
      return l10n.holidayValentines;
    case 'holidayWomensDayIntl':
      return l10n.holidayWomensDayIntl;
    case 'holidayChildrensDay':
      return l10n.holidayChildrensDay;
    case 'holidayHalloween':
      return l10n.holidayHalloween;
    case 'holidayChristmas':
      return l10n.holidayChristmas;
    default:
      return nameKey;
  }
}
