import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// Request notification permission separately (only call from foreground).
  static Future<void> requestPermission() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (_) {
      // May fail in background isolate — safe to ignore
    }
  }

  /// Transient notification (e.g. "Silent mode activated").
  static Future<void> show({
    required String title,
    required String body,
    int id = 0,
  }) async {
    const android = AndroidNotificationDetails(
      'silent_schedule_channel',
      'Silent Schedule',
      channelDescription: 'Alerts when silent mode activates or deactivates',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
    );
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);
    await _plugin.show(id, title, body, details);
  }

  /// Ongoing notification shown while a schedule is active.
  static Future<void> showOngoing({
    required String title,
    required String body,
  }) async {
    const android = AndroidNotificationDetails(
      'silent_schedule_active',
      'Active Schedule',
      channelDescription: 'Shown while a silent schedule is running',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
    );
    const details = NotificationDetails(android: android);
    await _plugin.show(999, title, body, details);
  }

  static Future<void> cancelOngoing() async {
    await _plugin.cancel(999);
  }
}
