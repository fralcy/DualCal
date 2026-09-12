import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../providers/calendar_provider.dart';
import '../utils/holiday_service.dart';
import 'day_cell.dart';

/// Renders the current month as a 7-column grid of [DayCell]s, with a
/// weekday header row respecting [firstDayOfWeek].
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.calendarProvider,
    required this.firstDayOfWeek,
    required this.onDaySelected,
    this.useSlideTransition = false,
  });

  final CalendarProvider calendarProvider;
  final int firstDayOfWeek;
  final ValueChanged<DateTime> onDaySelected;

  /// Which transition plays when [CalendarProvider.visibleMonth] changes:
  /// `false` (desktop/wide layouts) crossfades, `true` (mobile/narrow
  /// layouts, where a horizontal swipe already suggests paging) slides in
  /// the direction of [CalendarProvider.lastMonthDelta], like a page turn.
  final bool useSlideTransition;

  static const _holidayService = HolidayService();
  static const _transitionDuration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final days = calendarProvider.daysInGrid(firstDayOfWeek);
    final today = DateTime.now();
    final weekdayLabelsMonFirst = [
      l10n.weekdayMon,
      l10n.weekdayTue,
      l10n.weekdayWed,
      l10n.weekdayThu,
      l10n.weekdayFri,
      l10n.weekdaySat,
      l10n.weekdaySun,
    ];
    final weekdayLabelsSunFirst = [
      l10n.weekdaySun,
      l10n.weekdayMon,
      l10n.weekdayTue,
      l10n.weekdayWed,
      l10n.weekdayThu,
      l10n.weekdayFri,
      l10n.weekdaySat,
    ];
    final labels = firstDayOfWeek == DateTime.sunday
        ? weekdayLabelsSunFirst
        : weekdayLabelsMonFirst;

    return Column(
      children: [
        Row(
          children: labels
              .map(
                (l) => Expanded(
                  child: Center(
                    child: Text(l, style: Theme.of(context).textTheme.labelMedium),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Size cells to exactly fill the available width/height for
              // the actual row count (5 or 6 depending on the month) —
              // never forcing a square aspect ratio, and never taller
              // than the space we have, so the grid needs no scrollbar.
              final rows = (days.length / 7).ceil();
              final cellWidth = constraints.maxWidth / 7;
              final cellHeight = constraints.maxHeight / rows;

              final grid = GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: cellWidth / cellHeight,
                ),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final date = days[index];
                  final lunar = calendarProvider.lunarDateFor(date);
                  final holidays = _holidayService.holidaysOnDate(date);
                  return DayCell(
                    date: date,
                    lunarDate: lunar,
                    isCurrentMonth:
                        date.month == calendarProvider.visibleMonth.month,
                    isToday: _isSameDay(date, today),
                    isSelected:
                        _isSameDay(date, calendarProvider.selectedDate),
                    isDayOff: holidays.any((h) => h.isDayOff),
                    hasObservance: holidays.isNotEmpty,
                    onTap: () => onDaySelected(date),
                  );
                },
              );

              final monthKey = ValueKey(
                '${calendarProvider.visibleMonth.year}-${calendarProvider.visibleMonth.month}',
              );

              if (!useSlideTransition) {
                return AnimatedSwitcher(
                  duration: _transitionDuration,
                  child: KeyedSubtree(key: monthKey, child: grid),
                );
              }

              // Forward (next month) pushes both pages leftward: the new
              // grid enters from the right, the old one exits to the left.
              // Backward mirrors this. AnimatedSwitcher runs the outgoing
              // child's animation in reverse, so distinguishing on
              // AnimationStatus.reverse gives each child the correct side.
              final enterFromRight = calendarProvider.lastMonthDelta >= 0;
              return ClipRect(
                child: AnimatedSwitcher(
                  duration: _transitionDuration,
                  transitionBuilder: (child, animation) {
                    final isExiting = animation.status == AnimationStatus.reverse;
                    final beginOffset = isExiting
                        ? Offset(enterFromRight ? -1 : 1, 0)
                        : Offset(enterFromRight ? 1 : -1, 0);
                    final offsetAnimation = Tween<Offset>(
                      begin: beginOffset,
                      end: Offset.zero,
                    ).animate(animation);
                    return SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    );
                  },
                  child: KeyedSubtree(key: monthKey, child: grid),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
