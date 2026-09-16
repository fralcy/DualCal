import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/calendar_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/widgets/neumorphic_button.dart';
import '../../core/widgets/neumorphic_container.dart';
import '../responsive_screen.dart';

/// Small dialog/sheet to jump the calendar straight to a typed month/year,
/// instead of stepping one month at a time via the prev/next buttons —
/// opened by tapping the month/year label in the app bar.
Future<void> showJumpToMonthModal(BuildContext context) {
  final isDesktop = ResponsiveScreen.isDesktopSize(MediaQuery.sizeOf(context));

  if (isDesktop) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340, maxHeight: 280),
          child: const _JumpToMonthSheet(),
        ),
      ),
    );
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // See the identical pattern (and its comments) in
    // date_converter_modal.dart: the bottom padding gives the sheet a
    // reason to grow when the keyboard appears, and the height cap
    // guarantees a real scrollable viewport to scroll a focused field
    // into above the keyboard, instead of a short sheet with nowhere to
    // scroll.
    builder: (context) {
      final media = MediaQuery.of(context);
      return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
          child: const _JumpToMonthSheet(),
        ),
      );
    },
  );
}

class _JumpToMonthSheet extends StatefulWidget {
  const _JumpToMonthSheet();

  @override
  State<_JumpToMonthSheet> createState() => _JumpToMonthSheetState();
}

class _JumpToMonthSheetState extends State<_JumpToMonthSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _monthController;
  late final TextEditingController _yearController;

  @override
  void initState() {
    super.initState();
    final visibleMonth = context.read<CalendarProvider>().visibleMonth;
    _monthController = TextEditingController(text: '${visibleMonth.month}');
    _yearController = TextEditingController(text: '${visibleMonth.year}');
  }

  @override
  void dispose() {
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _go(AppLocalizations l10n) {
    if (!_formKey.currentState!.validate()) return;
    final month = int.parse(_monthController.text);
    final year = int.parse(_yearController.text);
    context.read<CalendarProvider>().jumpToMonth(year, month);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<SettingsProvider>().themeConfig;
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        child: NeumorphicContainer(
          padding: const EdgeInsets.all(20),
          borderRadius: 24,
          // A scrollable wrapper so this can't overflow if the on-screen
          // keyboard ever leaves less room than the form needs — matches
          // date_converter_modal.dart's structure.
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.jumpToMonthTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _monthController,
                          decoration: InputDecoration(
                            labelText: l10n.lunarMonthLabel,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) {
                            final month = int.tryParse(v ?? '');
                            return (month == null || month < 1 || month > 12)
                                ? ''
                                : null;
                          },
                          onFieldSubmitted: (_) => _go(l10n),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _yearController,
                          decoration: InputDecoration(
                            labelText: l10n.lunarYearLabel,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) {
                            final year = int.tryParse(v ?? '');
                            return (year == null || year < 1900 || year > 2200)
                                ? ''
                                : null;
                          },
                          onFieldSubmitted: (_) => _go(l10n),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: NeumorphicButton(
                      onTap: () => _go(l10n),
                      child: Text(l10n.jumpToMonthGoButton),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
