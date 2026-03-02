import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'providers/schedule_provider.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise background services
  await AndroidAlarmManager.initialize();
  await NotificationService.initialize();
  await NotificationService.requestPermission();

  runApp(const SilentScheduleApp());
}

class SilentScheduleApp extends StatelessWidget {
  const SilentScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScheduleProvider()..initialize(),
      child: MaterialApp(
        title: 'Silent Schedule',
        debugShowCheckedModeBanner: false,

        // ── Dark theme with teal / blue seed ──
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: const Color(0xFF1565C0),
          scaffoldBackgroundColor: const Color(0xFF0A1929),
          cardTheme: CardThemeData(
            color: const Color(0xFF132F4C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0A1929),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF1565C0),
        ),

        home: const HomeScreen(),
      ),
    );
  }
}
