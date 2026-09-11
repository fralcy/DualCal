import '../../models/calendar_event.dart';
import '../models/upcoming_reminder.dart';
import 'notification_service_base.dart';

/// Web has no reliable background-notification story (a browser tab that's
/// closed can't fire a local notification), so this implementation does no
/// real scheduling — it just keeps an in-memory list of resolved reminders
/// per event for `NotificationProvider` to render as an in-app list while
/// the app is open.
class NotificationService implements NotificationServiceBase {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final Map<String, List<UpcomingReminder>> _remindersByEvent = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> scheduleForEvent(
    CalendarEvent event,
    List<DateTime> occurrenceDates,
  ) async {
    final reminders = <UpcomingReminder>[];
    for (final occurrence in occurrenceDates) {
      final occurrenceDay =
          DateTime(occurrence.year, occurrence.month, occurrence.day);
      for (final daysBefore in event.reminderDaysBefore) {
        reminders.add(
          UpcomingReminder(
            eventId: event.id,
            eventTitle: event.title,
            occurrenceDate: occurrenceDay,
            reminderDate: occurrenceDay.subtract(Duration(days: daysBefore)),
            daysBefore: daysBefore,
          ),
        );
      }
    }
    _remindersByEvent[event.id] = reminders;
  }

  @override
  Future<void> cancelForEvent(String eventId) async {
    _remindersByEvent.remove(eventId);
  }

  /// Reminders due today or later, soonest first.
  @override
  List<UpcomingReminder> get upcomingReminders {
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    final all = _remindersByEvent.values
        .expand((r) => r)
        .where((r) => !r.reminderDate.isBefore(todayDay))
        .toList()
      ..sort((a, b) => a.reminderDate.compareTo(b.reminderDate));
    return all;
  }
}
