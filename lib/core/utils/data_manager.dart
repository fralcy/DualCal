import 'package:hive_flutter/hive_flutter.dart';

import '../../models/app_settings.dart';
import '../../models/calendar_event.dart';

/// Singleton owner of every Hive box in the app. `initialize()` runs once
/// in `main()`: registers all TypeAdapters, opens boxes, and seeds default
/// data if a box is empty. UI code never touches Hive directly — it goes
/// through a Provider, which goes through this class.
class DataManager {
  DataManager._internal();
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;

  static const String _eventsBoxName = 'calendar_events';
  static const String _settingsBoxName = 'app_settings';
  static const String _settingsKey = 'settings';

  late Box<CalendarEvent> _eventsBox;
  late Box<AppSettings> _settingsBox;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CalendarEventAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(EventDateTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(EventRecurrenceAdapter());
    }

    _eventsBox = await Hive.openBox<CalendarEvent>(_eventsBoxName);
    _settingsBox = await Hive.openBox<AppSettings>(_settingsBoxName);

    if (_settingsBox.get(_settingsKey) == null) {
      await _settingsBox.put(_settingsKey, AppSettings.initial());
    }

    _initialized = true;
  }

  // ---------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------

  AppSettings get settings => _settingsBox.get(_settingsKey)!;

  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put(_settingsKey, settings);
  }

  // ---------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------

  List<CalendarEvent> getAllEvents() => _eventsBox.values.toList();

  CalendarEvent? getEvent(String id) => _eventsBox.get(id);

  Future<void> saveEvent(CalendarEvent event) async {
    await _eventsBox.put(event.id, event);
  }

  Future<void> deleteEvent(String id) async {
    await _eventsBox.delete(id);
  }

  /// Replaces the entire events box with [events] — used by "replace" mode
  /// backup import.
  Future<void> replaceAllEvents(List<CalendarEvent> events) async {
    await _eventsBox.clear();
    await _eventsBox.putAll({for (final e in events) e.id: e});
  }

  /// Upserts [events] into the existing box by id — used by "merge" mode
  /// backup import.
  Future<void> mergeEvents(List<CalendarEvent> events) async {
    await _eventsBox.putAll({for (final e in events) e.id: e});
  }

  /// Resets all app data (events + settings back to defaults).
  Future<void> clearAll() async {
    await _eventsBox.clear();
    await _settingsBox.clear();
    await _settingsBox.put(_settingsKey, AppSettings.initial());
  }
}
