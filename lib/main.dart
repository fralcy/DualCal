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

    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: themeConfig.accent,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: themeConfig.background,
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'DualCal',
      theme: baseTheme.copyWith(
        // Material 3's default type scale goes as small as ~11sp
        // (labelSmall) — floor every named style at 13px so nothing in the
        // app reads as too small, without having to override every widget
        // that happens to use bodySmall/labelSmall individually.
        textTheme: _withMinFontSize(baseTheme.textTheme, 13),
      ),
      locale: Locale(settings.languageCode),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ResponsiveCalendarScreen(),
    );
  }
}

/// Returns a copy of [base] where every named style with a smaller
/// [TextStyle.fontSize] than [minSize] is raised to it, leaving styles that
/// are already at or above it untouched.
TextTheme _withMinFontSize(TextTheme base, double minSize) {
  TextStyle? clamped(TextStyle? style) {
    final size = style?.fontSize;
    if (style == null || size == null || size >= minSize) return style;
    return style.copyWith(fontSize: minSize);
  }

  return base.copyWith(
    displayLarge: clamped(base.displayLarge),
    displayMedium: clamped(base.displayMedium),
    displaySmall: clamped(base.displaySmall),
    headlineLarge: clamped(base.headlineLarge),
    headlineMedium: clamped(base.headlineMedium),
    headlineSmall: clamped(base.headlineSmall),
    titleLarge: clamped(base.titleLarge),
    titleMedium: clamped(base.titleMedium),
    titleSmall: clamped(base.titleSmall),
    bodyLarge: clamped(base.bodyLarge),
    bodyMedium: clamped(base.bodyMedium),
    bodySmall: clamped(base.bodySmall),
    labelLarge: clamped(base.labelLarge),
    labelMedium: clamped(base.labelMedium),
    labelSmall: clamped(base.labelSmall),
  );
}
