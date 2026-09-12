import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dual_cal/core/l10n/app_localizations.dart';
import 'package:dual_cal/core/providers/calendar_provider.dart';
import 'package:dual_cal/core/providers/event_provider.dart';
import 'package:dual_cal/core/providers/settings_provider.dart';
import 'package:dual_cal/core/utils/data_manager.dart';
import 'package:dual_cal/screens/responsive_calendar_screen.dart';

Widget _wrap(Widget child) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('dualcal_kb_test_');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
    await DataManager().initialize(hivePath: dir.path);
  });

  Future<void> pumpMobile(WidgetTester tester) async {
    // MediaQuery-driven layout choices (e.g. dialog vs. bottom-sheet
    // presentation) read `tester.view`, not `tester.binding.setSurfaceSize`
    // (which only affects raw render-surface/LayoutBuilder constraints) —
    // both need to agree that this is a narrow "mobile" viewport.
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_wrap(const ResponsiveCalendarScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('S opens Settings', (tester) async {
    await pumpMobile(tester);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(ResponsiveCalendarScreen)))!;

    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.pumpAndSettle();

    expect(find.text(l10n.themeSettingsTitle), findsOneWidget);
  });

  testWidgets('Escape no longer opens Settings at the top level', (tester) async {
    await pumpMobile(tester);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(ResponsiveCalendarScreen)))!;

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text(l10n.themeSettingsTitle), findsNothing);
  });

  testWidgets('Escape closes an open modal', (tester) async {
    await pumpMobile(tester);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(ResponsiveCalendarScreen)))!;

    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.pumpAndSettle();
    expect(find.text(l10n.themeSettingsTitle), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text(l10n.themeSettingsTitle), findsNothing);
  });

  testWidgets('Shift+PageDown advances the visible year, keeping the month',
      (tester) async {
    await pumpMobile(tester);
    final calendar = Provider.of<CalendarProvider>(
      tester.element(find.byType(ResponsiveCalendarScreen)),
      listen: false,
    );
    final before = calendar.visibleMonth;

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pumpAndSettle();

    expect(calendar.visibleMonth.year, before.year + 1);
    expect(calendar.visibleMonth.month, before.month);
  });

  testWidgets('Shift+PageUp goes back a year, keeping the month', (tester) async {
    await pumpMobile(tester);
    final calendar = Provider.of<CalendarProvider>(
      tester.element(find.byType(ResponsiveCalendarScreen)),
      listen: false,
    );
    final before = calendar.visibleMonth;

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pumpAndSettle();

    expect(calendar.visibleMonth.year, before.year - 1);
    expect(calendar.visibleMonth.month, before.month);
  });

  testWidgets('plain PageDown still only changes the month, not the year',
      (tester) async {
    await pumpMobile(tester);
    final calendar = Provider.of<CalendarProvider>(
      tester.element(find.byType(ResponsiveCalendarScreen)),
      listen: false,
    );
    final before = calendar.visibleMonth;

    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();

    expect(calendar.visibleMonth.year, before.year);
  });

  testWidgets('Space opens the day-detail sheet for the selected day',
      (tester) async {
    await pumpMobile(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    expect(find.textContaining('Âm lịch'), findsWidgets);
  });

  testWidgets('Shift+/ opens the shortcuts help sheet (native-platform chord)',
      (tester) async {
    await pumpMobile(tester);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(ResponsiveCalendarScreen)))!;

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pumpAndSettle();

    expect(find.text(l10n.shortcutsHelpTitle), findsOneWidget);
  });

  // Browsers report Shift+/ as LogicalKeyboardKey.question directly (via
  // event.key), not slash+shift — ResponsiveCalendarScreen binds both, but
  // flutter_test's key-event simulator can't synthesize a bare `question`
  // press (it has no "physical key" of its own to simulate), so that path
  // isn't covered by an automated test here.

  testWidgets(
      'a focused app-bar NeumorphicButton activates via Enter instead of '
      'the calendar-wide quick-add shortcut hijacking the key', (tester) async {
    await pumpMobile(tester);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(ResponsiveCalendarScreen)))!;

    final settingsButtonElement =
        tester.element(find.byIcon(Icons.palette_outlined));
    Focus.of(settingsButtonElement).requestFocus();
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    // Settings opened (not the quick-add new-event editor).
    expect(find.text(l10n.themeSettingsTitle), findsOneWidget);
    expect(find.text(l10n.titleLabel), findsNothing);
  });
}
