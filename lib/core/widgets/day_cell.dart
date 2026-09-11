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
    required this.onTap,
  });

  final DateTime date;
  final LunarDate lunarDate;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
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
        child: Column(
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
      ),
    );
  }
}
