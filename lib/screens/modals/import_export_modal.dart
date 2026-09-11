import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/event_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/backup_file.dart';
import '../../core/utils/backup_service.dart';
import '../../core/widgets/neumorphic_button.dart';
import '../../core/widgets/neumorphic_container.dart';

Future<void> showImportExportModal(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _ImportExportSheet(),
  );
}

class _ImportExportSheet extends StatefulWidget {
  const _ImportExportSheet();

  @override
  State<_ImportExportSheet> createState() => _ImportExportSheetState();
}

class _ImportExportSheetState extends State<_ImportExportSheet> {
  final _backupService = BackupService();
  bool _busy = false;

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
                l10n.backupSettingsTitle,
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
                    child: NeumorphicButton(
                      onTap: _busy ? () {} : _export,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.file_upload_outlined, size: 18),
                          const SizedBox(width: 8),
                          Flexible(child: Text(l10n.exportButton)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeumorphicButton(
                      onTap: _busy ? () {} : () => _import(merge: true),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.file_download_outlined, size: 18),
                          const SizedBox(width: 8),
                          Flexible(child: Text(l10n.importButton)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${l10n.importModeMerge} / ${l10n.importModeReplace}',
                style: TextStyle(fontSize: 11, color: t.textSecondary),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy ? null : () => _import(merge: false),
                  child: Text(l10n.importModeReplace),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final json = _backupService.exportToJson();
      final fileName =
          'dualcal_backup_${DateTime.now().toIso8601String().split('T').first}.json';
      final saved = await saveBackupFile(fileName, json);
      if (!mounted) return;
      _showSnackBar(saved != null ? l10n.exportSuccess : l10n.exportCancelled);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import({required bool merge}) async {
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final contents = await pickAndReadBackupFile();
      if (contents == null) {
        if (mounted) _showSnackBar(l10n.importCancelled);
        return;
      }
      final result =
          await _backupService.importFromJson(contents, merge: merge);
      if (!mounted) return;
      context.read<EventProvider>().refresh();
      context.read<SettingsProvider>().refresh();
      _showSnackBar(l10n.importSuccess(result.eventCount));
      Navigator.of(context).pop();
    } on BackupFormatException catch (e) {
      if (mounted) _showSnackBar(l10n.importError(e.message));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
