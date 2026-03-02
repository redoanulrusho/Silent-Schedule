import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../models/schedule_model.dart';
import 'storage_service.dart';
import 'sound_service.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
class AlarmService {
  // ── Initialise the alarm manager plugin ───────────────────────

  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  // ── Schedule start + end alarms for one schedule ──────────────

  static Future<void> scheduleAlarms(SilentSchedule schedule) async {
    if (!schedule.isEnabled) {
      await cancelAlarms(schedule);
      return;
    }

    // --- start alarm ---
    final startDt = _nextOccurrence(
      schedule.startHour,
      schedule.startMinute,
      schedule.selectedDays,
      schedule.repeatMode,
    );
    if (startDt != null) {
      await StorageService.saveAlarmMeta(schedule.startAlarmId, {
        'scheduleId': schedule.id,
        'isStart': true,
        'silentType': schedule.silentType.index,
        'label': schedule.label,
      });
      await AndroidAlarmManager.oneShotAt(
        startDt,
        schedule.startAlarmId,
        _onAlarmFired,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: false,
      );
    }

    // --- end alarm ---
    final endDt = _nextOccurrence(
      schedule.endHour,
      schedule.endMinute,
      schedule.selectedDays,
      schedule.repeatMode,
    );
    if (endDt != null) {
      await StorageService.saveAlarmMeta(schedule.endAlarmId, {
        'scheduleId': schedule.id,
        'isStart': false,
        'label': schedule.label,
      });
      await AndroidAlarmManager.oneShotAt(
        endDt,
        schedule.endAlarmId,
        _onAlarmFired,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: false,
      );
    }
  }

  static Future<void> cancelAlarms(SilentSchedule schedule) async {
    await AndroidAlarmManager.cancel(schedule.startAlarmId);
    await AndroidAlarmManager.cancel(schedule.endAlarmId);
    await StorageService.removeAlarmMeta(schedule.startAlarmId);
    await StorageService.removeAlarmMeta(schedule.endAlarmId);
  }

  // ── Re‑schedule every enabled schedule (e.g. on app launch) ───

  static Future<void> rescheduleAll() async {
    final schedules = await StorageService.loadSchedules();
    for (final s in schedules) {
      if (s.isEnabled) {
        try {
          await scheduleAlarms(s);
        } catch (e) {
          // Log but continue with remaining schedules
          // ignore: avoid_print
          print('Failed to schedule alarm for ${s.label}: $e');
        }
      }
    }
  }

  // ── Apply the correct ringer mode right now ───────────────────

  static Future<void> applyCurrentState() async {
    final schedules = await StorageService.loadSchedules();
    // Find ALL active schedules
    final actives = schedules.where((s) => s.isActiveNow()).toList();

    if (actives.isNotEmpty) {
      // Save the current mode BEFORE changing it (only if not already saved,
      // so overlapping schedules don't overwrite the original mode).
      final prev = await StorageService.getPreviousMode();
      if (prev == null || prev.isEmpty) {
        final current = await SoundService.getCurrentModeName();
        await StorageService.savePreviousMode(current);
      }

      // If any active schedule is "silent", use silent; otherwise vibrate
      final useSilent = actives.any((s) => s.silentType == SilentType.silent);
      if (useSilent) {
        await SoundService.setSilentMode();
      } else {
        await SoundService.setVibrateMode();
      }

      // Find the one with latest end time for the notification
      var latest = actives.first;
      for (final s in actives) {
        if ((s.endHour * 60 + s.endMinute) >
            (latest.endHour * 60 + latest.endMinute)) {
          latest = s;
        }
      }

      final names = actives.map((s) => s.label).join(', ');
      try {
        await NotificationService.showOngoing(
          title: actives.length == 1
              ? '${actives.first.label} — ${actives.first.silentTypeLabel} mode'
              : '${actives.length} schedules active',
          body: actives.length == 1
              ? '${actives.first.startTimeFormatted} → ${actives.first.endTimeFormatted}'
              : '$names  •  until ${latest.endTimeFormatted}',
        );
      } catch (_) {}
    } else {
      // No active schedules — ALWAYS restore normal mode and clean up.
      // This handles both: (a) end-of-schedule, and (b) user toggling off.
      await SoundService.setNormalMode();
      await StorageService.savePreviousMode('');
      try {
        await NotificationService.cancelOngoing();
      } catch (_) {}
    }
  }

  // ── Private: compute next DateTime for a given time + days ────

  static DateTime? _nextOccurrence(
    int hour,
    int minute,
    List<int> days,
    ScheduleRepeatMode mode,
  ) {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour, minute);

    if (mode == ScheduleRepeatMode.daily) {
      if (target.isBefore(now) || target.isAtSameMomentAs(now)) {
        target = target.add(const Duration(days: 1));
      }
      return target;
    }

    if (mode == ScheduleRepeatMode.selectedDays) {
      for (var i = 0; i < 8; i++) {
        final candidate = target.add(Duration(days: i));
        if (days.contains(candidate.weekday) && candidate.isAfter(now)) {
          return candidate;
        }
      }
      return null;
    }

    // ScheduleRepeatMode.once
    if (target.isAfter(now)) return target;
    return null;
  }

  // ── Background alarm callback (runs in an isolate) ────────────

  @pragma('vm:entry-point')
  static Future<void> _onAlarmFired(int alarmId) async {
    final meta = await StorageService.getAlarmMeta(alarmId);
    if (meta == null) return;

    final isStart = meta['isStart'] as bool;
    final label = meta['label'] as String;

    if (isStart) {
      // Save the mode we're about to override (only if not already saved,
      // so overlapping schedules don't overwrite the original normal mode).
      final prev = await StorageService.getPreviousMode();
      if (prev == null || prev.isEmpty) {
        final current = await SoundService.getCurrentModeName();
        await StorageService.savePreviousMode(current);
      }

      final type = SilentType.values[meta['silentType'] as int];
      if (type == SilentType.silent) {
        await SoundService.setSilentMode();
      } else {
        await SoundService.setVibrateMode();
      }

      try {
        await NotificationService.initialize();
        await NotificationService.showOngoing(
          title: '$label — active',
          body: 'Your phone is now silenced.',
        );
      } catch (_) {}
    } else {
      // End of schedule: check if any OTHER schedule is still active
      final schedules = await StorageService.loadSchedules();
      final otherActives = schedules
          .where((s) => s.id != meta['scheduleId'] && s.isActiveNow())
          .toList();

      if (otherActives.isNotEmpty) {
        // Other schedules still running — choose the strictest mode
        final useSilent = otherActives.any(
          (s) => s.silentType == SilentType.silent,
        );
        if (useSilent) {
          await SoundService.setSilentMode();
        } else {
          await SoundService.setVibrateMode();
        }

        // Find the one with the latest end time for notification
        var latest = otherActives.first;
        for (final s in otherActives) {
          if ((s.endHour * 60 + s.endMinute) >
              (latest.endHour * 60 + latest.endMinute)) {
            latest = s;
          }
        }
        try {
          await NotificationService.initialize();
          if (otherActives.length == 1) {
            await NotificationService.showOngoing(
              title: '${otherActives.first.label} — active',
              body:
                  'Still silenced until ${otherActives.first.endTimeFormatted}',
            );
          } else {
            final names = otherActives.map((s) => s.label).join(', ');
            await NotificationService.showOngoing(
              title: '${otherActives.length} schedules active',
              body: '$names  •  until ${latest.endTimeFormatted}',
            );
          }
        } catch (_) {}
      } else {
        // No other schedule active — restore normal
        await SoundService.setNormalMode();
        await StorageService.savePreviousMode('');
        try {
          await NotificationService.initialize();
          await NotificationService.cancelOngoing();
          await NotificationService.show(
            title: '$label — ended',
            body: 'Your phone is back to normal mode.',
          );
        } catch (_) {}
      }
    }

    // Reschedule the next occurrence (if repeating)
    await _reschedule(meta);
  }

  static Future<void> _reschedule(Map<String, dynamic> meta) async {
    final scheduleId = meta['scheduleId'] as String;
    final schedules = await StorageService.loadSchedules();
    SilentSchedule? match;
    for (final s in schedules) {
      if (s.id == scheduleId) {
        match = s;
        break;
      }
    }
    if (match != null &&
        match.isEnabled &&
        match.repeatMode != ScheduleRepeatMode.once) {
      await scheduleAlarms(match);
    }
  }
}
