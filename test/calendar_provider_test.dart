import 'package:flutter_test/flutter_test.dart';

import 'package:dual_cal/core/providers/calendar_provider.dart';

void main() {
  late CalendarProvider provider;

  setUp(() {
    provider = CalendarProvider();
  });

  group('jumpToMonth', () {
    test('updates visibleMonth to the given year/month', () {
      provider.jumpToMonth(2030, 7);
      expect(provider.visibleMonth, DateTime(2030, 7));
    });

    test('lastMonthDelta is +1 when jumping to any month after the current one',
        () {
      final before = provider.visibleMonth;
      provider.jumpToMonth(before.year + 5, before.month);
      expect(provider.lastMonthDelta, 1);
    });

    test('lastMonthDelta is -1 when jumping to any month before the current one',
        () {
      final before = provider.visibleMonth;
      provider.jumpToMonth(before.year - 5, before.month);
      expect(provider.lastMonthDelta, -1);
    });

    test('lastMonthDelta is 0 when jumping to the same month already visible',
        () {
      final before = provider.visibleMonth;
      provider.jumpToMonth(before.year, before.month);
      expect(provider.lastMonthDelta, 0);
    });

    test('clamps selectedDate into the target month when the day does not exist there',
        () {
      // Land on day 31 in a month that has one, then jump to February —
      // selectedDate must clamp down instead of overflowing into March.
      provider.jumpToMonth(2026, 1);
      provider.selectDate(DateTime(2026, 1, 31));

      provider.jumpToMonth(2026, 2);

      expect(provider.selectedDate.year, 2026);
      expect(provider.selectedDate.month, 2);
      expect(provider.selectedDate.day, 28); // 2026 is not a leap year
    });

    test('notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);
      provider.jumpToMonth(2030, 1);
      expect(notified, isTrue);
    });
  });
}
