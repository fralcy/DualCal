import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/calendar_provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/widgets/day_detail_content.dart';
import '../core/widgets/month_grid.dart';
import '../core/widgets/neumorphic_button.dart';
import '../core/widgets/neumorphic_container.dart';
import 'modals/date_converter_modal.dart';
import 'modals/jump_to_month_modal.dart';
import 'modals/settings_modal.dart';

/// Desktop layout: month grid on the left, a persistent side panel on the
/// right showing the selected day's detail — no modal needed since there's
/// room for both at once.
class DesktopLandscapeCalendarScreen extends StatelessWidget {
  const DesktopLandscapeCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final calendar = context.watch<CalendarProvider>();
    final themeConfig = context.watch<SettingsProvider>().themeConfig;
    final monthLabel =
        '${calendar.visibleMonth.month}/${calendar.visibleMonth.year}';

    return Scaffold(
      backgroundColor: themeConfig.background,
      appBar: AppBar(
        backgroundColor: themeConfig.background,
        elevation: 0,
        title: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => showJumpToMonthModal(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              monthLabel,
              style: TextStyle(color: themeConfig.textPrimary),
            ),
          ),
        ),
        // Previously in `leading:`, which AppBar forces into a fixed square
        // slot (56px by default) — unlike `actions`, whose children just
        // size to their own content. That made this button visibly bigger
        // than its neighbors; keeping all 4 in `actions` sizes them alike.
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(6),
            child: NeumorphicButton(
              padding: const EdgeInsets.all(6),
              onTap: calendar.goToPreviousMonth,
              child: const Icon(Icons.chevron_left, size: 20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: NeumorphicButton(
              padding: const EdgeInsets.all(6),
              onTap: calendar.goToNextMonth,
              child: const Icon(Icons.chevron_right, size: 20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: NeumorphicButton(
              padding: const EdgeInsets.all(6),
              onTap: calendar.goToToday,
              child: const Icon(Icons.today, size: 20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: NeumorphicButton(
              padding: const EdgeInsets.all(6),
              onTap: () => showDateConverterModal(context),
              child: const Icon(Icons.sync_alt, size: 20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: NeumorphicButton(
              padding: const EdgeInsets.all(6),
              onTap: () => showSettingsModal(context),
              child: const Icon(Icons.palette_outlined, size: 20),
            ),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: NeumorphicContainer(
                padding: const EdgeInsets.all(12),
                borderRadius: 24,
                child: MonthGrid(
                  calendarProvider: calendar,
                  firstDayOfWeek: DateTime.monday,
                  onDaySelected: calendar.selectDate,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
            child: SizedBox(
              width: 320,
              child: NeumorphicContainer(
                padding: EdgeInsets.zero,
                borderRadius: 24,
                child: DayDetailContent(date: calendar.selectedDate),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
