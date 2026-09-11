import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../models/calendar_event.dart';
import '../models/upcoming_reminder.dart';
import 'notification_service_base.dart';

const _reminderHour = 8; // fire reminders at 08:00 local time

/// Mobile/desktop reminder scheduling via `flutter_local_notifications`.
/// Recurring (yearly) events are NOT scheduled as OS-recurring alarms —
/// native recurrence only understands the solar calendar, not lunar — so
/// `NotificationProvider` pre-resolves each event's next couple of
/// occurrences to concrete solar dates and this class schedules each one
/// as a plain one-time notification.
class NotificationService implements NotificationServiceBase {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await _plugin.initialize(settings);

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS || Platform.isMacOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
  }

  @override
  Future<void> scheduleForEvent(
    CalendarEvent event,
    List<DateTime> occurrenceDates,
  ) async {
    await cancelForEvent(event.id);
    if (!_initialized) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'dualcal_reminders',
        'Nhắc nhở sự kiện',
        channelDescription: 'Thông báo nhắc nhở ghi chú/sự kiện DualCal',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    final now = DateTime.now();
    var slot = 0;
    for (final occurrence in occurrenceDates) {
      final occurrenceDay =
          DateTime(occurrence.year, occurrence.month, occurrence.day);
      for (final daysBefore in event.reminderDaysBefore) {
        if (slot >= _maxRemindersPerEvent) break;

        final fireDay = occurrenceDay.subtract(Duration(days: daysBefore));
        final fireAt =
            DateTime(fireDay.year, fireDay.month, fireDay.day, _reminderHour);
        if (fireAt.isBefore(now)) {
          slot++;
          continue;
        }

        await _plugin.zonedSchedule(
          _notificationId(event.id, slot),
          event.title,
          daysBefore == 0 ? 'Hôm nay' : 'Còn $daysBefore ngày nữa',
          tz.TZDateTime.from(fireAt, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: event.id,
        );
        slot++;
      }
    }
  }

  @override
  Future<void> cancelForEvent(String eventId) async {
    // Cancel a fixed range of possible slot ids for this event — simpler
    // and safer than persisting exactly which ids ended up scheduled.
    for (var i = 0; i < _maxRemindersPerEvent; i++) {
      await _plugin.cancel(_notificationId(eventId, i));
    }
  }

  static const _maxRemindersPerEvent = 64;

  /// Stable id derived from the event id's hash plus a slot index —
  /// flutter_local_notifications ids must fit in a 32-bit platform int.
  int _notificationId(String eventId, int slot) {
    return (eventId.hashCode.abs() % 1000000) * 100 + slot;
  }

  /// Real OS notifications handle the "upcoming" story on this platform,
  /// so there's no need to duplicate it as an in-app list.
  @override
  List<UpcomingReminder> get upcomingReminders => const [];
}
