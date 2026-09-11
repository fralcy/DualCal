import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/providers/calendar_provider.dart';
import 'core/providers/event_provider.dart';
import 'core/utils/data_manager.dart';
import 'screens/responsive_calendar_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await DataManager().initialize();
  } catch (e, st) {
    // A storage init failure shouldn't produce a blank crash screen — the
    // app still runs, just without persisted events/settings this session.
    debugPrint('DataManager init failed: $e\n$st');
  }

  runApp(const DualCalApp());
}

class DualCalApp extends StatelessWidget {
  const DualCalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: MaterialApp(
        title: 'DualCal',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const ResponsiveCalendarScreen(),
      ),
    );
  }
}
