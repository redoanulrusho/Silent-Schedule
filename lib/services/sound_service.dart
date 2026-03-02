import 'dart:io';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:permission_handler/permission_handler.dart';

/// Thin wrapper around the platform sound‑mode API.
class SoundService {
  // ── Query ─────────────────────────────────────────────────────

  static Future<String> getCurrentModeName() async {
    try {
      final mode = await SoundMode.ringerModeStatus;
      switch (mode) {
        case RingerModeStatus.silent:
          return 'Silent';
        case RingerModeStatus.vibrate:
          return 'Vibrate';
        case RingerModeStatus.normal:
        default:
          return 'Normal';
      }
    } catch (_) {
      return 'Unknown';
    }
  }

  // ── Mutate ────────────────────────────────────────────────────

  static Future<bool> setSilentMode() async {
    try {
      await SoundMode.setSoundMode(RingerModeStatus.silent);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setVibrateMode() async {
    try {
      await SoundMode.setSoundMode(RingerModeStatus.vibrate);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setNormalMode() async {
    try {
      await SoundMode.setSoundMode(RingerModeStatus.normal);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Permissions (Android DND policy) ──────────────────────────

  static Future<bool> hasDndPermission() async {
    if (!Platform.isAndroid) return true; // iOS doesn't need this
    try {
      return (await Permission.accessNotificationPolicy.status).isGranted;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestDndPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final result = await Permission.accessNotificationPolicy.request();
      return result.isGranted;
    } catch (_) {
      return false;
    }
  }
}
