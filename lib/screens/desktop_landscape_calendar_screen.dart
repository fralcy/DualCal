import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/calendar_provider.dart';
import '../core/widgets/day_detail_content.dart';
import '../core/widgets/month_grid.dart';

/// Desktop layout: month grid on the left, a persistent side panel on the
/// right showing the selected day's detail — no modal needed since there's
/// room for both at once.
class DesktopLandscapeCalendarScreen extends StatelessWidget {
  const DesktopLandscapeCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final calendar = context.watch<CalendarProvider>();
    final monthLabel =
        '${calendar.visibleMonth.month}/${calendar.visibleMonth.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text(monthLabel),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: calendar.goToPreviousMonth,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: calendar.goToNextMonth,
          ),
          IconButton(icon: const Icon(Icons.today), onPressed: calendar.goToToday),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: MonthGrid(
                calendarProvider: calendar,
                firstDayOfWeek: DateTime.monday,
                onDaySelected: calendar.selectDate,
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          SizedBox(
            width: 320,
            child: DayDetailContent(date: calendar.selectedDate),
          ),
        ],
      ),
    );
  }
}
