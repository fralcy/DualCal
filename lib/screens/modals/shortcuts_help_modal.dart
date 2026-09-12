import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/widgets/neumorphic_container.dart';
import '../responsive_screen.dart';

/// A read-only reference sheet listing every calendar keyboard shortcut —
/// opened with "?", mirroring the convention used by Gmail, Google
/// Calendar, Trello, and GitHub.
Future<void> showShortcutsHelpModal(BuildContext context) {
  final isDesktop = ResponsiveScreen.isDesktopSize(MediaQuery.sizeOf(context));

  if (isDesktop) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
          child: const _ShortcutsHelpSheet(),
        ),
      ),
    );
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _ShortcutsHelpSheet(),
  );
}

class _ShortcutsHelpSheet extends StatelessWidget {
  const _ShortcutsHelpSheet();

  @override
  Widget build(BuildContext context) {
    final t = context.watch<SettingsProvider>().themeConfig;
    final l10n = AppLocalizations.of(context)!;

    final entries = <(String, String)>[
      ('← / →', l10n.shortcutsMoveDay),
      ('↑ / ↓', l10n.shortcutsMoveWeek),
      ('Page Up / Page Down', l10n.shortcutsChangeMonth),
      ('Shift + Page Up / Page Down', l10n.shortcutsChangeYear),
      ('Home / T', l10n.shortcutsGoToday),
      ('Enter', l10n.shortcutsQuickAdd),
      ('Space', l10n.shortcutsOpenDayDetail),
      ('S', l10n.shortcutsOpenSettings),
      ('?', l10n.shortcutsShowHelp),
      ('Escape', l10n.shortcutsCloseModal),
    ];

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
                  l10n.shortcutsHelpTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ...entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 160,
                          child: Text(
                            entry.$1,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: t.accent,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.$2,
                            style: TextStyle(color: t.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
