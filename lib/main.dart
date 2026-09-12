import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/l10n/app_localizations.dart';
import 'core/providers/calendar_provider.dart';
import 'core/providers/event_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/utils/data_manager.dart';
import 'screens/responsive_calendar_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await DataManager().initialize();
  } catch (e, st) {
    // A storage init failure shouldn't produce a blank crash screen — the
    // app still runs, just without persisted events/settings this session.
    debugPrint('DataManager init failed: $e\n$st');
  }

  runApp(const DualCalApp());
}

class DualCalApp extends StatelessWidget {
  const DualCalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(
          create: (context) {
            final notificationProvider = NotificationProvider(
              eventProvider: context.read<EventProvider>(),
            );
            notificationProvider.init();
            return notificationProvider;
          },
        ),
      ],
      child: const _ThemedApp(),
    );
  }
}

/// Split out from [DualCalApp] so `MaterialApp`'s theme can watch
/// [SettingsProvider] — a widget can't watch a provider declared by the
/// very [MultiProvider] wrapping it.
class _ThemedApp extends StatelessWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final themeConfig = settings.themeConfig;
    final brightness =
        ThemeData.estimateBrightnessForColor(themeConfig.background);

    return MaterialApp(
      title: 'DualCal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeConfig.accent,
          brightness: brightness,
        ),
        scaffoldBackgroundColor: themeConfig.background,
        useMaterial3: true,
      ),
      locale: Locale(settings.languageCode),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ResponsiveCalendarScreen(),
    );
  }
}
