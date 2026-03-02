import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Silent Schedule';
  static const String schedulesKey = 'silent_schedules';
  static const String alarmMetaPrefix = 'alarm_meta_';
  static const String previousModeKey = 'previous_sound_mode';

  // Notification channel
  static const String notifChannelId = 'silent_schedule_channel';
  static const String notifChannelName = 'Silent Schedule';
  static const String activeChannelId = 'silent_schedule_active';
  static const String activeChannelName = 'Active Schedule';
}

class AppColors {
  static const Color primaryDark = Color(0xFF0A1929);
  static const Color surface = Color(0xFF132F4C);
  static const Color cardDark = Color(0xFF1A3A5C);
  static const Color accent = Color(0xFF00BFA5);
  static const Color accentLight = Color(0xFF64FFDA);
  static const Color silentRed = Color(0xFFEF5350);
  static const Color vibrateAmber = Color(0xFFFFB74D);
  static const Color normalGreen = Color(0xFF66BB6A);
}

class DayHelper {
  static const List<String> shortNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const List<String> singleLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const List<String> fullNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
}
