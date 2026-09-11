import 'package:flutter/material.dart';

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
  });

  final CalendarProvider calendarProvider;
  final int firstDayOfWeek;
  final ValueChanged<DateTime> onDaySelected;

  static const _weekdayLabelsMonFirst = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];
  static const _weekdayLabelsSunFirst = [
    'CN',
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
  ];

  static const _holidayService = HolidayService();

  @override
  Widget build(BuildContext context) {
    final days = calendarProvider.daysInGrid(firstDayOfWeek);
    final today = DateTime.now();
    final labels = firstDayOfWeek == DateTime.sunday
        ? _weekdayLabelsSunFirst
        : _weekdayLabelsMonFirst;

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
          child: GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
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
                isSelected: _isSameDay(date, calendarProvider.selectedDate),
                isDayOff: holidays.any((h) => h.isDayOff),
                hasObservance: holidays.isNotEmpty,
                onTap: () => onDaySelected(date),
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
