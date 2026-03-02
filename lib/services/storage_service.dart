import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_model.dart';
import '../utils/constants.dart';

class StorageService {
  // ── Schedules ─────────────────────────────────────────────────

  static Future<List<SilentSchedule>> loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    // Reload from disk in case data was written by another isolate
    await prefs.reload();
    final raw = prefs.getString(AppConstants.schedulesKey);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list
        .map((e) => SilentSchedule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveSchedules(List<SilentSchedule> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(schedules.map((s) => s.toJson()).toList());
    await prefs.setString(AppConstants.schedulesKey, raw);
  }

  // ── Alarm metadata (used by background isolate) ───────────────

  static Future<void> saveAlarmMeta(
    int alarmId,
    Map<String, dynamic> meta,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${AppConstants.alarmMetaPrefix}$alarmId',
      jsonEncode(meta),
    );
  }

  static Future<Map<String, dynamic>?> getAlarmMeta(int alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    // Reload from disk in case data was written by another isolate
    await prefs.reload();
    final raw = prefs.getString('${AppConstants.alarmMetaPrefix}$alarmId');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> removeAlarmMeta(int alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${AppConstants.alarmMetaPrefix}$alarmId');
  }

  // ── Previous ringer mode (so we can restore it) ───────────────

  static Future<void> savePreviousMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.previousModeKey, mode);
  }

  static Future<String?> getPreviousMode() async {
    final prefs = await SharedPreferences.getInstance();
    // Reload from disk in case data was written by another isolate
    await prefs.reload();
    return prefs.getString(AppConstants.previousModeKey);
  }
}
