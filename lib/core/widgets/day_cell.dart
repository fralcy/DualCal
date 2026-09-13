import 'package:flutter/material.dart';

import '../models/lunar_date.dart';

/// A single day in the month grid: solar day number as the primary label,
/// lunar day number as a small subtitle (shown as "day/month" on the 1st of
/// a lunar month, to mark the transition).
class DayCell extends StatelessWidget {
  const DayCell({
    super.key,
    required this.date,
    required this.lunarDate,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.isDayOff,
    required this.hasObservance,
    required this.eventColors,
    required this.hasMoreEventColors,
    required this.onTap,
  });

  final DateTime date;
  final LunarDate lunarDate;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;

  /// Official public holiday (e.g. Tết, Quốc khánh) — rendered in the
  /// error/accent color to stand out from regular days.
  final bool isDayOff;

  /// A non-dayoff observance (e.g. Trung Thu, Valentine's Day) — rendered
  /// as a small dot rather than recoloring the day number.
  final bool hasObservance;

  /// Up to 3 of the day's own note/event category colors (from
  /// `eventCategoryColors`), one dot each — deliberately the *actual*
  /// category color rather than a generic theme accent, since every
  /// preset theme's accent happens to be close in hue to one of the 8
  /// selectable category colors (e.g. the "Sand" theme's orange accent vs.
  /// the orange category), which would make a generic indicator easy to
  /// mistake for that specific category.
  final List<Color> eventColors;

  /// Whether the day has more distinct category colors than fit in
  /// [eventColors] — shown as one extra dot in the theme's own accent
  /// color, which is never one of the real category dots, so it reads
  /// unambiguously as "there's more" rather than a 4th category.
  final bool hasMoreEventColors;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimmed = !isCurrentMonth;

    final Color solarColor;
    if (isSelected) {
      solarColor = theme.colorScheme.onPrimary;
    } else if (dimmed) {
      solarColor = theme.disabledColor;
    } else if (isDayOff) {
      solarColor = theme.colorScheme.error;
    } else {
      solarColor = theme.colorScheme.onSurface;
    }

    final Color lunarColor;
    if (isSelected) {
      lunarColor = theme.colorScheme.onPrimary.withValues(alpha: 0.8);
    } else if (dimmed) {
      lunarColor = theme.disabledColor;
    } else {
      lunarColor = theme.colorScheme.secondary;
    }

    return InkWell(
      onTap: onTap,
      // Day selection already has its own arrow-key roving-focus mechanism
      // (see ResponsiveCalendarScreen) — excluding cells from the normal
      // Tab order avoids tabbing through 42 cells and having Tab-focus and
      // arrow-key selection fight over what "Enter" should do.
      canRequestFocus: false,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : isToday
                  ? theme.colorScheme.primaryContainer
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        // LayoutBuilder so text scales with the cell's actual rendered
        // size (which itself now varies with the grid's available
        // height/width — see MonthGrid) instead of a fixed font size
        // that's either too small on a roomy desktop row or overflowing
        // on a cramped mobile one.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellHeight = constraints.maxHeight;
            final solarFontSize = (cellHeight * 0.30).clamp(13.0, 24.0);
            final lunarFontSize = (cellHeight * 0.16).clamp(13.0, 14.0);
            final dotSize = (cellHeight * 0.05).clamp(3.0, 6.0);

            // Stack (not a 3rd Column row) so the observance dot never
            // pushes the cell taller than the grid's row height allows.
            return Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      style: TextStyle(
                        fontSize: solarFontSize,
                        height: 1.1,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                        color: solarColor,
                      ),
                      child: Text('${date.day}'),
                    ),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      style: TextStyle(
                        fontSize: lunarFontSize,
                        height: 1.1,
                        color: lunarColor,
                      ),
                      child: Text(
                        lunarDate.day == 1
                            ? '${lunarDate.day}/${lunarDate.month}'
                            : '${lunarDate.day}',
                      ),
                    ),
                  ],
                ),
                if ((hasObservance && !isDayOff) ||
                    eventColors.isNotEmpty ||
                    hasMoreEventColors)
                  Positioned(
                    bottom: cellHeight * 0.08,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final dot in [
                          if (hasObservance && !isDayOff)
                            isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.tertiary,
                          for (final c in eventColors)
                            isSelected ? theme.colorScheme.onPrimary : c,
                          if (hasMoreEventColors)
                            isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.primary,
                        ])
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: dotSize * 0.3,
                            ),
                            child: _Dot(size: dotSize, color: dot),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
