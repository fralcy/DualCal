import '../../models/calendar_event.dart';
import '../models/upcoming_reminder.dart';
import 'notification_service_base.dart';

/// Fallback implementation selected when neither `dart.library.io` nor
/// `dart.library.js` applies. Flutter always has one of the two, so this
/// exists only to keep the conditional-export exhaustive; it behaves like
/// the web implementation (no real scheduling).
class NotificationService implements NotificationServiceBase {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  @override
  Future<void> init() async {}

  @override
  Future<void> scheduleForEvent(
    CalendarEvent event,
    List<DateTime> occurrenceDates,
  ) async {}

  @override
  Future<void> cancelForEvent(String eventId) async {}

  @override
  List<UpcomingReminder> get upcomingReminders => const [];
}
