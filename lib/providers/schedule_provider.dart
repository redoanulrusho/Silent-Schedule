import 'dart:async';
import 'package:flutter/material.dart';
import '../models/schedule_model.dart';
import '../services/storage_service.dart';
import '../services/alarm_service.dart';
import '../services/sound_service.dart';

class ScheduleProvider extends ChangeNotifier {
  List<SilentSchedule> _schedules = [];
  bool _isLoading = true;
  bool _hasDndPermission = false;
  String _currentMode = 'Normal';
  Timer? _refreshTimer;

  // ── Getters ───────────────────────────────────────────────────

  List<SilentSchedule> get schedules => List.unmodifiable(_schedules);
  bool get isLoading => _isLoading;
  bool get hasDndPermission => _hasDndPermission;
  String get currentMode => _currentMode;

  /// All currently active schedules (supports overlapping).
  List<SilentSchedule> get activeSchedules =>
      _schedules.where((s) => s.isActiveNow()).toList();

  /// Convenience: first active schedule (for backward compat).
  SilentSchedule? get activeSchedule {
    final list = activeSchedules;
    return list.isEmpty ? null : list.first;
  }

  /// The latest end time among all currently overlapping active schedules.
  String get latestEndTime {
    final list = activeSchedules;
    if (list.isEmpty) return '';
    // Find the one with the latest end‑of‑day minutes
    var latest = list.first;
    for (final s in list) {
      final sMin = s.endHour * 60 + s.endMinute;
      final lMin = latest.endHour * 60 + latest.endMinute;
      if (sMin > lMin) latest = s;
    }
    return latest.endTimeFormatted;
  }

  int get activeCount => _schedules.where((s) => s.isEnabled).length;

  // ── Init ──────────────────────────────────────────────────────

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _schedules = await StorageService.loadSchedules();
    _hasDndPermission = await SoundService.hasDndPermission();
    await _refreshMode();

    // Make sure alarms are registered & current state is applied
    try {
      await AlarmService.rescheduleAll();
      await AlarmService.applyCurrentState();
    } catch (e) {
      debugPrint('AlarmService init error: $e');
    }
    await _refreshMode();

    _isLoading = false;
    notifyListeners();

    // Start periodic refresh so ACTIVE labels update in real time
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners(); // re-evaluate isActiveNow() for all cards
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ── CRUD ──────────────────────────────────────────────────────

  Future<void> addSchedule(SilentSchedule schedule) async {
    _schedules.add(schedule);
    await _persist();
    try {
      await AlarmService.scheduleAlarms(schedule);
    } catch (e) {
      debugPrint('Schedule alarm error: $e');
    }
    await _applyAndRefresh();
    notifyListeners();
  }

  Future<void> updateSchedule(SilentSchedule schedule) async {
    final idx = _schedules.indexWhere((s) => s.id == schedule.id);
    if (idx == -1) return;
    try {
      await AlarmService.cancelAlarms(_schedules[idx]);
    } catch (_) {}
    _schedules[idx] = schedule;
    await _persist();
    try {
      await AlarmService.scheduleAlarms(schedule);
    } catch (e) {
      debugPrint('Schedule alarm error: $e');
    }
    await _applyAndRefresh();
    notifyListeners();
  }

  Future<void> deleteSchedule(String id) async {
    final idx = _schedules.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    try {
      await AlarmService.cancelAlarms(_schedules[idx]);
    } catch (_) {}
    _schedules.removeAt(idx);
    await _persist();
    await _applyAndRefresh();
    notifyListeners();
  }

  Future<void> toggleSchedule(String id) async {
    final idx = _schedules.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    _schedules[idx].isEnabled = !_schedules[idx].isEnabled;
    await _persist();
    if (_schedules[idx].isEnabled) {
      await AlarmService.scheduleAlarms(_schedules[idx]);
    } else {
      await AlarmService.cancelAlarms(_schedules[idx]);
    }
    await _applyAndRefresh();
    notifyListeners();
  }

  // ── Permissions ───────────────────────────────────────────────

  Future<void> requestDndPermission() async {
    _hasDndPermission = await SoundService.requestDndPermission();
    notifyListeners();
  }

  // ── Refresh ───────────────────────────────────────────────────

  Future<void> refreshCurrentMode() async {
    await _refreshMode();
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────

  Future<void> _persist() => StorageService.saveSchedules(_schedules);

  Future<void> _refreshMode() async {
    _currentMode = await SoundService.getCurrentModeName();
  }

  Future<void> _applyAndRefresh() async {
    await AlarmService.applyCurrentState();
    await _refreshMode();
  }
}
