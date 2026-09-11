import 'package:hive/hive.dart';

part 'app_settings.g.dart';

/// Singleton settings record — DataManager keeps exactly one instance of
/// this in its Hive box, created via [AppSettings.initial] on first launch.
@HiveType(typeId: 1)
class AppSettings extends HiveObject {
  @HiveField(0)
  String languageCode;

  @HiveField(1)
  String themeId;

  @HiveField(2)
  List<int> defaultReminderDaysBefore;

  @HiveField(3)
  int firstDayOfWeek;

  AppSettings({
    required this.languageCode,
    required this.themeId,
    required this.defaultReminderDaysBefore,
    this.firstDayOfWeek = DateTime.monday,
  });

  factory AppSettings.initial() {
    return AppSettings(
      languageCode: 'vi',
      themeId: 'sky',
      defaultReminderDaysBefore: [1],
      firstDayOfWeek: DateTime.monday,
    );
  }

  AppSettings copyWith({
    String? languageCode,
    String? themeId,
    List<int>? defaultReminderDaysBefore,
    int? firstDayOfWeek,
  }) {
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      themeId: themeId ?? this.themeId,
      defaultReminderDaysBefore:
          defaultReminderDaysBefore ?? this.defaultReminderDaysBefore,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
    );
  }
}
