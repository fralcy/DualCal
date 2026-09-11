import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/calendar_event.dart';
import '../../screens/modals/event_editor_modal.dart';
import '../constants/event_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/event_provider.dart';
import '../utils/holiday_l10n.dart';
import '../utils/holiday_service.dart';
import '../utils/lunar_calendar_service.dart';

/// Shared content for the selected day's detail — used as the desktop side
/// panel and as the body of the mobile bottom-sheet modal, so the two
/// layouts never duplicate this UI.
class DayDetailContent extends StatelessWidget {
  const DayDetailContent({super.key, required this.date});

  final DateTime date;

  static const _lunarCalendarService = LunarCalendarService();
  static const _holidayService = HolidayService();

  @override
  Widget build(BuildContext context) {
    final lunar = _lunarCalendarService.solarToLunar(date);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final events = context.watch<EventProvider>().eventsForDate(date);
    final holidays = _holidayService.holidaysOnDate(date);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${date.day}/${date.month}/${date.year}',
                style: theme.textTheme.headlineSmall,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: l10n.addNote,
                onPressed: () => showEventEditorModal(context, initialDate: date),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.lunarDatePrefix}${lunar.day}/${lunar.month}'
            '${lunar.isLeapMonth ? l10n.leapMonthSuffix : ""}/${lunar.year}',
            style: theme.textTheme.bodyMedium,
          ),
          if (holidays.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...holidays.map(
              (h) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    h.isDayOff ? Icons.event_busy : Icons.celebration_outlined,
                    size: 16,
                    color: h.isDayOff
                        ? theme.colorScheme.error
                        : theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    resolveHolidayName(l10n, h.nameKey),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: h.isDayOff
                          ? theme.colorScheme.error
                          : theme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (events.isEmpty)
            Text(l10n.noNotesForDay, style: theme.textTheme.bodySmall)
          else
            ...events.map((e) => _EventTile(event: e, date: date)),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, required this.date});

  final CalendarEvent event;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 8,
        backgroundColor: eventCategoryColors[event.colorTag % eventCategoryColors.length],
      ),
      title: Text(event.title),
      subtitle: event.description == null ? null : Text(event.description!),
      onTap: () => showEventEditorModal(context, initialDate: date, existing: event),
    );
  }
}
