import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/calendar_provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/widgets/month_grid.dart';
import '../core/widgets/neumorphic_button.dart';
import '../core/widgets/neumorphic_container.dart';
import 'modals/date_converter_modal.dart';
import 'modals/day_detail_modal.dart';
import 'modals/jump_to_month_modal.dart';
import 'modals/settings_modal.dart';

/// Mobile layout: month grid fills the screen, tapping a day opens the
/// detail as a bottom sheet.
class MobilePortraitCalendarScreen extends StatelessWidget {
  const MobilePortraitCalendarScreen({super.key});

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
      body: GestureDetector(
        // Swipe left/right to change month — the touch-screen equivalent
        // of the Page Up/Down keyboard shortcut. Swipe up/down to change
        // year — the equivalent of Shift+Page Up/Page Down.
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -200) {
            calendar.goToNextMonth();
          } else if (velocity > 200) {
            calendar.goToPreviousMonth();
          }
        },
        onVerticalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          final current = calendar.visibleMonth;
          if (velocity < -200) {
            calendar.jumpToMonth(current.year + 1, current.month);
          } else if (velocity > 200) {
            calendar.jumpToMonth(current.year - 1, current.month);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: NeumorphicContainer(
            padding: const EdgeInsets.all(8),
            borderRadius: 20,
            child: MonthGrid(
              calendarProvider: calendar,
              firstDayOfWeek: DateTime.monday,
              useSlideTransition: true,
              onDaySelected: (date) {
                calendar.selectDate(date);
                showDayDetailModal(context, date);
              },
            ),
          ),
        ),
      ),
    );
  }
}
