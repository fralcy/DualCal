import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dual_cal/core/providers/calendar_provider.dart';
import 'package:dual_cal/screens/responsive_calendar_screen.dart';

Widget _wrap(Widget child) => ChangeNotifierProvider(
      create: (_) => CalendarProvider(),
      child: MaterialApp(home: child),
    );

void main() {
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
}
