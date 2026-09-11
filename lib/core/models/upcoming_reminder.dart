/// A reminder resolved to a concrete future date. Only the web notification
/// implementation actually keeps a list of these in memory — mobile/desktop
/// rely on real OS-scheduled notifications instead — but the type is
/// shared so `NotificationProvider` can render an in-app list regardless
/// of platform.
class UpcomingReminder {
  const UpcomingReminder({
    required this.eventId,
    required this.eventTitle,
    required this.occurrenceDate,
    required this.reminderDate,
    required this.daysBefore,
  });

  final String eventId;
  final String eventTitle;

  /// The date the event itself falls on.
  final DateTime occurrenceDate;

  /// The date the reminder should fire (occurrenceDate - daysBefore).
  final DateTime reminderDate;

  final int daysBefore;
}
