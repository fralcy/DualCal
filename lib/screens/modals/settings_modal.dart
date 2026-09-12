import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/neumorphic_themes.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/widgets/neumorphic_button.dart';
import '../../core/widgets/neumorphic_container.dart';
import '../responsive_screen.dart';
import 'import_export_modal.dart';

/// Desktop/landscape shows this as a centered dialog; mobile/portrait keeps
/// the bottom-sheet presentation.
Future<void> showSettingsModal(BuildContext context) {
  final isDesktop = ResponsiveScreen.isDesktopSize(MediaQuery.sizeOf(context));

  if (isDesktop) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 640),
          child: const _SettingsSheet(),
        ),
      ),
    );
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final t = settings.themeConfig;
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        child: NeumorphicContainer(
          padding: const EdgeInsets.all(20),
          borderRadius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.themeSettingsTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: neumorphicThemePresets
                    .map((preset) => _ThemeSwatch(preset: preset))
                    .toList(),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.languageSettingsTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const [
                  _LanguageOption(code: 'vi', label: 'Tiếng Việt'),
                  _LanguageOption(code: 'en', label: 'English'),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                l10n.backupSettingsTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              NeumorphicButton(
                onTap: () {
                  Navigator.of(context).pop();
                  showImportExportModal(context);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.backup_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.backupSettingsTitle),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.preset});

  final NeumorphicThemeConfig preset;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final selected = settings.themeId == preset.id;

    return NeumorphicButton(
      selected: selected,
      onTap: () => settings.setThemeId(preset.id),
      borderRadius: 16,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: preset.accent,
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(color: preset.textPrimary, width: 2)
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(preset.label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({required this.code, required this.label});

  final String code;
  final String label;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final selected = settings.languageCode == code;

    return NeumorphicButton(
      selected: selected,
      onTap: () => settings.setLanguageCode(code),
      borderRadius: 16,
      child: SizedBox(
        width: 100,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}
