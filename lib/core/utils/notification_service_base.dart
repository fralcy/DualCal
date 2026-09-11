import '../../models/calendar_event.dart';
import '../models/upcoming_reminder.dart';

/// Shared shape implemented identically by `notification_service_stub.dart`,
/// `_io.dart`, and `_web.dart`. `NotificationService` itself can't be a
/// single class (each platform file defines its own, picked by conditional
/// export), so this interface exists purely so `NotificationProvider` can
/// depend on a testable type instead of the concrete platform singleton.
abstract class NotificationServiceBase {
  Future<void> init();

  /// Schedules a reminder for each of the event's `reminderDaysBefore`
  /// entries against each of [occurrenceDates] (already resolved to
  /// concrete future solar dates by the caller).
  Future<void> scheduleForEvent(
    CalendarEvent event,
    List<DateTime> occurrenceDates,
  );

  Future<void> cancelForEvent(String eventId);

  /// Populated on web only — mobile/desktop rely on real OS notifications
  /// instead of an in-app list.
  List<UpcomingReminder> get upcomingReminders;
}
