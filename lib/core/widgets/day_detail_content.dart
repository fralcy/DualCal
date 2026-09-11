import 'package:flutter/material.dart';

import '../utils/lunar_calendar_service.dart';

/// Shared content for the selected day's detail — used as the desktop side
/// panel and as the body of the mobile bottom-sheet modal, so the two
/// layouts never duplicate this UI.
///
/// Event list wiring lands in Milestone 3 once `EventProvider` exists.
class DayDetailContent extends StatelessWidget {
  const DayDetailContent({super.key, required this.date});

  final DateTime date;

  static const _lunarCalendarService = LunarCalendarService();

  @override
  Widget build(BuildContext context) {
    final lunar = _lunarCalendarService.solarToLunar(date);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${date.day}/${date.month}/${date.year}',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Âm lịch: ${lunar.day}/${lunar.month}'
            '${lunar.isLeapMonth ? " (nhuận)" : ""}/${lunar.year}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có ghi chú cho ngày này.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
