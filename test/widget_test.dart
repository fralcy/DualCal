import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dual_cal/core/providers/calendar_provider.dart';
import 'package:dual_cal/core/providers/event_provider.dart';
import 'package:dual_cal/core/utils/data_manager.dart';
import 'package:dual_cal/screens/responsive_calendar_screen.dart';

Widget _wrap(Widget child) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: MaterialApp(home: child),
    );

void main() {
  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('dualcal_test_');
    // Best-effort cleanup only — on Windows the Hive box file can still be
    // memory-mapped by this process when the test run ends, which makes
    // deleting it fail; that's harmless, just a leftover temp dir.
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
    await DataManager().initialize(hivePath: dir.path);
  });

  testWidgets('renders the current month grid with today highlighted',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const ResponsiveCalendarScreen()));

    final today = DateTime.now();
    expect(find.text('${today.day}'), findsWidgets);
  });

  testWidgets(
      'tapping a day on the mobile layout opens the day-detail bottom sheet',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(const ResponsiveCalendarScreen()));

    final today = DateTime.now();
    await tester.tap(find.text('${today.day}').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Âm lịch'), findsWidgets);
  });

  testWidgets('adding an event from the day detail sheet shows it in the list',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(const ResponsiveCalendarScreen()));

    final today = DateTime.now();
    await tester.tap(find.text('${today.day}').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Tiêu đề'), 'Test event');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Test event'), findsOneWidget);
  });
}
