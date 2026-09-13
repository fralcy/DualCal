import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/event_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/calendar_provider.dart';
import '../providers/event_provider.dart';
import '../utils/holiday_service.dart';
import 'day_cell.dart';

/// Renders the current month as a 7-column, 6-row grid of [DayCell]s, with
/// a weekday header row respecting [firstDayOfWeek].
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

  /// Always 6 rows — [CalendarProvider.daysInGrid] always returns 42 cells
  /// precisely so every month renders at the same cell size; a 5-week
  /// month rendering taller cells than a 6-week one would add a jarring
  /// size jump on top of whichever transition is playing.
  static const _rows = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final eventProvider = context.watch<EventProvider>();
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
              final cellWidth = constraints.maxWidth / 7;
              final cellHeight = constraints.maxHeight / _rows;

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

                  // The day's own distinct category colors, in the order
                  // they were first seen — capped at 3 dots so the cell
                  // doesn't get crowded when many differently-tagged notes
                  // land on the same day (see hasMoreEventColors below for
                  // what represents "more than that").
                  final dayEvents = eventProvider.eventsForDate(date);
                  final uniqueColorTags = <int>{};
                  for (final e in dayEvents) {
                    uniqueColorTags.add(e.colorTag % eventCategoryColors.length);
                  }
                  final eventColors = uniqueColorTags
                      .take(3)
                      .map((tag) => eventCategoryColors[tag])
                      .toList();

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
                    eventColors: eventColors,
                    hasMoreEventColors: uniqueColorTags.length > 3,
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

              return _SlideMonthTransition(
                transitionKey: monthKey,
                direction: calendarProvider.lastMonthDelta,
                duration: _transitionDuration,
                child: grid,
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

/// Page-turn transition: the new month enters alongside the current one,
/// then both slide together in the same direction until the new month has
/// fully taken the old one's place. Deliberately not built on
/// [AnimatedSwitcher] — driving both the outgoing and incoming child off a
/// single [AnimationController] guarantees they move in lockstep, rather
/// than relying on AnimatedSwitcher's internal forward/reverse timing to
/// happen to line up.
class _SlideMonthTransition extends StatefulWidget {
  const _SlideMonthTransition({
    required this.child,
    required this.transitionKey,
    required this.direction,
    required this.duration,
  });

  final Widget child;
  final Key transitionKey;

  /// Sign of the month change that produced [child]: +1 forward (new
  /// month slides in from the right), -1 backward (from the left).
  final int direction;

  final Duration duration;

  @override
  State<_SlideMonthTransition> createState() => _SlideMonthTransitionState();
}

class _SlideMonthTransitionState extends State<_SlideMonthTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Widget? _outgoingChild;
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..value = 1; // settled — no transition plays for the very first child
  }

  @override
  void didUpdateWidget(covariant _SlideMonthTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transitionKey != widget.transitionKey) {
      _outgoingChild = oldWidget.child;
      _direction = widget.direction == 0 ? 1 : widget.direction;
      _controller
        ..value = 0
        ..forward().whenComplete(() {
          if (mounted) setState(() => _outgoingChild = null);
        });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outgoing = _outgoingChild;
    // Incoming: starts fully off-screen in the direction of travel, ends
    // centered. Outgoing: starts centered, ends fully off-screen the
    // opposite way — both driven by the same t, so they move in lockstep.
    final incomingOffset = Tween<Offset>(
      begin: Offset(_direction.toDouble(), 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    final outgoingOffset = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-_direction.toDouble(), 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    return ClipRect(
      child: Stack(
        children: [
          if (outgoing != null)
            Positioned.fill(
              child: SlideTransition(position: outgoingOffset, child: outgoing),
            ),
          Positioned.fill(
            child: SlideTransition(
              position: incomingOffset,
              child: KeyedSubtree(key: widget.transitionKey, child: widget.child),
            ),
          ),
        ],
      ),
    );
  }
}
