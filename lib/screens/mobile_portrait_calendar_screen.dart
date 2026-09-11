import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/calendar_provider.dart';
import '../core/widgets/month_grid.dart';
import 'modals/day_detail_modal.dart';

/// Mobile layout: month grid fills the screen, tapping a day opens the
/// detail as a bottom sheet.
class MobilePortraitCalendarScreen extends StatelessWidget {
  const MobilePortraitCalendarScreen({super.key});

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
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: MonthGrid(
          calendarProvider: calendar,
          firstDayOfWeek: DateTime.monday,
          onDaySelected: (date) {
            calendar.selectDate(date);
            showDayDetailModal(context, date);
          },
        ),
      ),
    );
  }
}
