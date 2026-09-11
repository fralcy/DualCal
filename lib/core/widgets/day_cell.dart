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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : isToday
                  ? theme.colorScheme.primaryContainer
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        // Stack (not a 3rd Column row) so the observance dot never pushes
        // the cell taller than the grid's fixed row height allows.
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: solarColor,
                  ),
                ),
                Text(
                  lunarDate.day == 1
                      ? '${lunarDate.day}/${lunarDate.month}'
                      : '${lunarDate.day}',
                  style: TextStyle(fontSize: 10, color: lunarColor),
                ),
              ],
            ),
            if (hasObservance && !isDayOff)
              Positioned(
                bottom: 0,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
