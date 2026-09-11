import 'package:hive/hive.dart';

part 'calendar_event.g.dart';

/// typeId registry (do not reuse or renumber once shipped):
/// 0 = CalendarEvent, 1 = AppSettings, 2 = EventDateType, 3 = EventRecurrence.

@HiveType(typeId: 2)
enum EventDateType {
  @HiveField(0)
  solar,
  @HiveField(1)
  lunar,
}

@HiveType(typeId: 3)
enum EventRecurrence {
  @HiveField(0)
  none,
  @HiveField(1)
  yearly,
}

/// A user-created note/event attached to a specific date, anchored either to
/// the solar or the lunar calendar, optionally repeating every year.
@HiveType(typeId: 0)
class CalendarEvent extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  EventDateType dateType;

  /// Set when [dateType] is solar.
  @HiveField(4)
  DateTime? solarDate;

  /// Set when [dateType] is lunar.
  @HiveField(5)
  int? lunarDay;

  @HiveField(6)
  int? lunarMonth;

  @HiveField(7)
  int? lunarYear;

  @HiveField(8)
  bool isLeapMonth;

  @HiveField(9)
  EventRecurrence recurrence;

  /// Number of days before the occurrence to fire a reminder, e.g. [0, 1, 3].
  @HiveField(10)
  List<int> reminderDaysBefore;

  /// Index into the fixed category-color palette (`core/constants/event_colors.dart`).
  @HiveField(11)
  int colorTag;

  @HiveField(12)
  String? category;

  @HiveField(13)
  DateTime createdAt;

  @HiveField(14)
  DateTime updatedAt;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.dateType,
    this.solarDate,
    this.lunarDay,
    this.lunarMonth,
    this.lunarYear,
    this.isLeapMonth = false,
    this.recurrence = EventRecurrence.none,
    List<int>? reminderDaysBefore,
    this.colorTag = 0,
    this.category,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : reminderDaysBefore = reminderDaysBefore ?? const [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory CalendarEvent.create({
    required String id,
    required String title,
    String? description,
    required EventDateType dateType,
    DateTime? solarDate,
    int? lunarDay,
    int? lunarMonth,
    int? lunarYear,
    bool isLeapMonth = false,
    EventRecurrence recurrence = EventRecurrence.none,
    List<int> reminderDaysBefore = const [],
    int colorTag = 0,
    String? category,
  }) {
    final now = DateTime.now();
    return CalendarEvent(
      id: id,
      title: title,
      description: description,
      dateType: dateType,
      solarDate: solarDate,
      lunarDay: lunarDay,
      lunarMonth: lunarMonth,
      lunarYear: lunarYear,
      isLeapMonth: isLeapMonth,
      recurrence: recurrence,
      reminderDaysBefore: List<int>.from(reminderDaysBefore),
      colorTag: colorTag,
      category: category,
      createdAt: now,
      updatedAt: now,
    );
  }

  CalendarEvent copyWith({
    String? title,
    String? description,
    EventDateType? dateType,
    DateTime? solarDate,
    int? lunarDay,
    int? lunarMonth,
    int? lunarYear,
    bool? isLeapMonth,
    EventRecurrence? recurrence,
    List<int>? reminderDaysBefore,
    int? colorTag,
    String? category,
  }) {
    return CalendarEvent(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateType: dateType ?? this.dateType,
      solarDate: solarDate ?? this.solarDate,
      lunarDay: lunarDay ?? this.lunarDay,
      lunarMonth: lunarMonth ?? this.lunarMonth,
      lunarYear: lunarYear ?? this.lunarYear,
      isLeapMonth: isLeapMonth ?? this.isLeapMonth,
      recurrence: recurrence ?? this.recurrence,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      colorTag: colorTag ?? this.colorTag,
      category: category ?? this.category,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
