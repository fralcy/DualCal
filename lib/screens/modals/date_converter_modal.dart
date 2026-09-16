import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/neumorphic_themes.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/lunar_date.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/lunar_calendar_service.dart';
import '../../core/widgets/neumorphic_button.dart';
import '../../core/widgets/neumorphic_container.dart';
import '../responsive_screen.dart';

/// Two-column solar <-> lunar date converter: the left column is always the
/// input, the right column is always the result — a swap button flips
/// which calendar type occupies each side, rather than moving the columns
/// themselves.
Future<void> showDateConverterModal(BuildContext context) {
  final isDesktop = ResponsiveScreen.isDesktopSize(MediaQuery.sizeOf(context));

  if (isDesktop) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460, maxHeight: 520),
          child: const _ConverterSheet(),
        ),
      ),
    );
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _ConverterSheet(),
  );
}

class _ConverterSheet extends StatefulWidget {
  const _ConverterSheet();

  @override
  State<_ConverterSheet> createState() => _ConverterSheetState();
}

class _ConverterSheetState extends State<_ConverterSheet> {
  static const _lunarService = LunarCalendarService();

  bool _inputIsLunar = false;

  DateTime _solarInput = DateTime.now();

  int _lunarDay = 1;
  int _lunarMonth = 1;
  bool _isLeapInput = false;

  /// Position in the 60-year Can Chi cycle (0-59), picked via the
  /// autocomplete field — null means "not specified", falling back to the
  /// plain "most recent years" search regardless of Can Chi.
  int? _canChiIndex;

  List<LunarYearMatch> _matches = const [];
  int? _nextSearchYear;

  @override
  void initState() {
    super.initState();
    _resetLunarSearch();
  }

  /// One search step, dispatching to whichever method matches whether a
  /// Can Chi filter is active — candidate years step by 1 without it, by
  /// 60 (Can Chi always repeats on a 60-year cycle) with it.
  List<LunarYearMatch> _search(int startYear) {
    final canChiIndex = _canChiIndex;
    if (canChiIndex != null) {
      return _lunarService.findRecentYearsForCanChi(
        _lunarDay,
        _lunarMonth,
        canChiIndex,
        isLeapMonth: _isLeapInput,
        startYear: startYear,
      );
    }
    return _lunarService.findRecentYearsFor(
      _lunarDay,
      _lunarMonth,
      isLeapMonth: _isLeapInput,
      startYear: startYear,
    );
  }

  /// Re-runs the lunar->solar search from the current year, replacing any
  /// existing results — called whenever the lunar input (day/month/leap/Can
  /// Chi) or the swap direction changes. Not wrapped in `setState` itself
  /// since it also needs to run once from `initState`, before the first
  /// build.
  void _resetLunarSearch() {
    if (!_inputIsLunar) {
      _matches = const [];
      _nextSearchYear = null;
      return;
    }
    final matches = _search(DateTime.now().year);
    _matches = matches;
    _nextSearchYear = matches.isEmpty
        ? null
        : matches.last.lunarYear - (_canChiIndex != null ? 60 : 1);
  }

  void _loadMoreYears() {
    final startYear = _nextSearchYear;
    if (startYear == null) return;
    final more = _search(startYear);
    setState(() {
      _matches = [..._matches, ...more];
      _nextSearchYear = more.isEmpty
          ? null
          : more.last.lunarYear - (_canChiIndex != null ? 60 : 1);
    });
  }

  void _swap() {
    setState(() {
      _inputIsLunar = !_inputIsLunar;
      // Reset rather than carry over: the Can Chi text field itself always
      // starts empty again after a swap (it's rebuilt fresh), so leaving
      // the old index set would silently keep filtering by a Can Chi the
      // field no longer visibly shows.
      _canChiIndex = null;
      _resetLunarSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<SettingsProvider>().themeConfig;
    final l10n = AppLocalizations.of(context)!;
    final isVietnamese = Localizations.localeOf(context).languageCode == 'vi';

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        child: NeumorphicContainer(
          padding: const EdgeInsets.all(20),
          borderRadius: 24,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.converterTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                // Deliberately not IntrinsicHeight-wrapped: forcing both
                // columns to the same height clipped/overflowed the taller
                // one (the lunar dropdowns + checkbox) once its Expanded
                // was constrained to the shorter column's intrinsic height.
                // Plain Row + crossAxisAlignment.start just lets each
                // column size to its own content.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildInputColumn(l10n, t, isVietnamese)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Tooltip(
                        message: l10n.converterSwapTooltip,
                        child: NeumorphicButton(
                          padding: const EdgeInsets.all(8),
                          onTap: _swap,
                          child: const Icon(Icons.swap_horiz, size: 20),
                        ),
                      ),
                    ),
                    Expanded(child: _buildResultColumn(l10n, t, isVietnamese)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputColumn(
    AppLocalizations l10n,
    NeumorphicThemeConfig t,
    bool isVietnamese,
  ) {
    if (!_inputIsLunar) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dateTypeSolar, style: TextStyle(color: t.textSecondary)),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${_solarInput.day}/${_solarInput.month}/${_solarInput.year}',
            ),
            trailing: const Icon(Icons.calendar_today, size: 18),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _solarInput,
                firstDate: DateTime(1900),
                lastDate: DateTime(2200),
              );
              if (picked != null) setState(() => _solarInput = picked);
            },
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.dateTypeLunar, style: TextStyle(color: t.textSecondary)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _lunarDay,
          decoration: InputDecoration(labelText: l10n.lunarDayLabel),
          items: List.generate(
            30,
            (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
          ),
          onChanged: (v) => setState(() {
            _lunarDay = v ?? _lunarDay;
            _resetLunarSearch();
          }),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _lunarMonth,
          decoration: InputDecoration(labelText: l10n.lunarMonthLabel),
          items: List.generate(
            12,
            (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
          ),
          onChanged: (v) => setState(() {
            _lunarMonth = v ?? _lunarMonth;
            _resetLunarSearch();
          }),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: _isLeapInput,
          title: Text(l10n.leapMonthLabel),
          onChanged: (v) => setState(() {
            _isLeapInput = v ?? false;
            _resetLunarSearch();
          }),
        ),
        const SizedBox(height: 8),
        _CanChiField(
          key: ValueKey(isVietnamese),
          label: l10n.converterCanChiLabel,
          options: isVietnamese ? allCanChiNamesVi : allCanChiNamesEnglish,
          onChanged: (index) => setState(() {
            _canChiIndex = index;
            _resetLunarSearch();
          }),
        ),
      ],
    );
  }

  Widget _buildResultColumn(
    AppLocalizations l10n,
    NeumorphicThemeConfig t,
    bool isVietnamese,
  ) {
    if (!_inputIsLunar) {
      final lunar = _lunarService.solarToLunar(_solarInput);
      final canChi = isVietnamese ? lunar.canChi : lunar.canChiEnglish;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.converterResultLabel,
            style: TextStyle(color: t.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '${lunar.day}/${lunar.month}'
            '${lunar.isLeapMonth ? l10n.leapMonthSuffix : ""}/${lunar.year}',
            style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(canChi, style: TextStyle(color: t.textSecondary)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.converterResultLabel,
          style: TextStyle(color: t.textSecondary),
        ),
        const SizedBox(height: 8),
        if (_matches.isEmpty)
          Text(l10n.converterNoResult, style: TextStyle(color: t.textSecondary))
        else
          ..._matches.map((m) {
            final canChiForMatch = isVietnamese
                ? canChiForYear(m.lunarYear)
                : canChiEnglishForYear(m.lunarYear);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${m.lunarYear} ($canChiForMatch)',
                    style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${m.solarDate.day}/${m.solarDate.month}/${m.solarDate.year}',
                    style: TextStyle(color: t.textSecondary),
                  ),
                ],
              ),
            );
          }),
        if (_nextSearchYear != null)
          NeumorphicButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onTap: _loadMoreYears,
            child: Text(
              l10n.converterLoadMoreYears,
              style: const TextStyle(fontSize: 13),
            ),
          ),
      ],
    );
  }
}

/// Autocomplete for picking one of the 60 Can Chi names — narrows the
/// lunar->solar search from "the N most recent years with this lunar
/// day/month" (which could easily NOT be the year someone actually means)
/// to "the N most recent years with this lunar day/month *and* this exact
/// Can Chi", useful when someone knows e.g. "mùng 10 tháng 3 năm Giáp
/// Thìn" but not which specific year that was. Left blank, the search
/// falls back to ignoring Can Chi entirely.
class _CanChiField extends StatelessWidget {
  const _CanChiField({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final List<String> options;

  /// Called with the selected name's index into [options], or null once
  /// the field is cleared / no longer matches a valid name exactly.
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (value) {
        if (value.text.isEmpty) return const Iterable<String>.empty();
        final query = value.text.toLowerCase();
        return options.where((o) => o.toLowerCase().contains(query));
      },
      onSelected: (selection) => onChanged(options.indexOf(selection)),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(labelText: label),
          onChanged: (text) {
            if (text.isEmpty) {
              onChanged(null);
              return;
            }
            final exactIndex = options.indexWhere(
              (o) => o.toLowerCase() == text.toLowerCase(),
            );
            if (exactIndex != -1) onChanged(exactIndex);
          },
        );
      },
    );
  }
}
