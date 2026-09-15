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

  List<LunarYearMatch> _matches = const [];
  int? _nextSearchYear;

  @override
  void initState() {
    super.initState();
    _resetLunarSearch();
  }

  /// Re-runs the lunar->solar search from the current year, replacing any
  /// existing results — called whenever the lunar input (day/month/leap) or
  /// the swap direction changes. Not wrapped in `setState` itself since it
  /// also needs to run once from `initState`, before the first build.
  void _resetLunarSearch() {
    if (!_inputIsLunar) {
      _matches = const [];
      _nextSearchYear = null;
      return;
    }
    final matches = _lunarService.findRecentYearsFor(
      _lunarDay,
      _lunarMonth,
      isLeapMonth: _isLeapInput,
      startYear: DateTime.now().year,
    );
    _matches = matches;
    _nextSearchYear = matches.isEmpty ? null : matches.last.lunarYear - 1;
  }

  void _loadMoreYears() {
    final startYear = _nextSearchYear;
    if (startYear == null) return;
    final more = _lunarService.findRecentYearsFor(
      _lunarDay,
      _lunarMonth,
      isLeapMonth: _isLeapInput,
      startYear: startYear,
    );
    setState(() {
      _matches = [..._matches, ...more];
      _nextSearchYear = more.isEmpty ? null : more.last.lunarYear - 1;
    });
  }

  void _swap() {
    setState(() {
      _inputIsLunar = !_inputIsLunar;
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
                    Expanded(child: _buildInputColumn(l10n, t)),
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

  Widget _buildInputColumn(AppLocalizations l10n, NeumorphicThemeConfig t) {
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
