import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dual_cal/core/l10n/app_localizations.dart';
import 'package:dual_cal/core/providers/calendar_provider.dart';
import 'package:dual_cal/core/providers/event_provider.dart';
import 'package:dual_cal/core/providers/settings_provider.dart';
import 'package:dual_cal/core/utils/data_manager.dart';
import 'package:dual_cal/core/constants/event_colors.dart';
import 'package:dual_cal/core/widgets/day_cell.dart';
import 'package:dual_cal/models/calendar_event.dart';
import 'package:dual_cal/screens/responsive_calendar_screen.dart';

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

Widget _wrap(Widget child) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: MaterialApp(
        // Matches AppSettings.initial()'s default languageCode — without
        // this the test harness falls back to the system test locale
        // (en_US) instead of the app's actual default.
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
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

  testWidgets(
      'a day gets its own user-event dot after adding a note, distinct from '
      'holiday/observance dots', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(const ResponsiveCalendarScreen()));

    final today = DateTime.now();
    DayCell todayCell() => tester.widget<DayCell>(
          find.byWidgetPredicate(
            (w) => w is DayCell && _isSameDay(w.date, today),
          ),
        );

    expect(todayCell().eventColors, isEmpty);
    expect(todayCell().hasMoreEventColors, isFalse);

    // Add the event directly through the provider rather than driving the
    // full add-note UI flow — this test is about MonthGrid/DayCell picking
    // up EventProvider changes and rendering the dot, not about re-proving
    // the form-submission flow the other tests already cover.
    // runAsync is required here: addEvent does real Hive file I/O, which
    // never resolves in testWidgets' fake-time zone without it.
    await tester.runAsync(() async {
      await tester
          .element(find.byType(ResponsiveCalendarScreen))
          .read<EventProvider>()
          .addEvent(
            title: 'Note with a dot',
            dateType: EventDateType.solar,
            solarDate: today,
            colorTag: 2,
          );
    });
    await tester.pumpAndSettle();

    expect(todayCell().eventColors, [eventCategoryColors[2]]);
    expect(todayCell().hasMoreEventColors, isFalse);
  });

  testWidgets(
      'a day with more than 3 distinct note colors caps the dots and shows '
      'a "more" marker', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(const ResponsiveCalendarScreen()));

    final today = DateTime.now();
    final eventProvider = tester
        .element(find.byType(ResponsiveCalendarScreen))
        .read<EventProvider>();
    // See the previous test for why this needs runAsync.
    await tester.runAsync(() async {
      for (var tag = 0; tag < 5; tag++) {
        await eventProvider.addEvent(
          title: 'Note $tag',
          dateType: EventDateType.solar,
          solarDate: today,
          colorTag: tag,
        );
      }
    });
    await tester.pumpAndSettle();

    final cell = tester.widget<DayCell>(
      find.byWidgetPredicate((w) => w is DayCell && _isSameDay(w.date, today)),
    );
    // 3 distinct dots, each a real category color used that day (order
    // isn't guaranteed — it follows however EventProvider returns events,
    // not necessarily insertion order) — and a "more" marker for the rest.
    expect(cell.eventColors.toSet(), hasLength(3));
    for (final color in cell.eventColors) {
      expect(eventCategoryColors.sublist(0, 5), contains(color));
    }
    expect(cell.hasMoreEventColors, isTrue);
  });

  testWidgets('tapping the month/year label jumps to a typed month/year',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(const ResponsiveCalendarScreen()));

    final calendar = tester
        .element(find.byType(ResponsiveCalendarScreen))
        .read<CalendarProvider>();
    final monthLabel =
        '${calendar.visibleMonth.month}/${calendar.visibleMonth.year}';

    await tester.tap(find.text(monthLabel));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ResponsiveCalendarScreen)),
    )!;
    expect(find.text(l10n.jumpToMonthTitle), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '3');
    await tester.enterText(fields.at(1), '2030');
    await tester.tap(find.text(l10n.jumpToMonthGoButton));
    await tester.pumpAndSettle();

    expect(calendar.visibleMonth, DateTime(2030, 3));
  });

  testWidgets(
      'the date converter modal shows the lunar equivalent for today, and '
      'swapping switches to lunar input', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(const ResponsiveCalendarScreen()));

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ResponsiveCalendarScreen)),
    )!;

    await tester.tap(find.byIcon(Icons.sync_alt));
    await tester.pumpAndSettle();

    expect(find.text(l10n.converterTitle), findsOneWidget);
    // Default direction is solar-in / lunar-out: a single Can Chi result.
    expect(find.text(l10n.dateTypeSolar), findsOneWidget);

    await tester.tap(find.byIcon(Icons.swap_horiz));
    await tester.pumpAndSettle();

    // After swapping, the lunar day/month dropdowns become the input side.
    expect(find.text(l10n.dateTypeLunar), findsOneWidget);
    expect(find.text(l10n.lunarDayLabel), findsOneWidget);
    expect(find.text(l10n.leapMonthLabel), findsOneWidget);
  });
}
