enum ScheduleRepeatMode { daily, selectedDays, once }

enum SilentType { silent, vibrate }

class SilentSchedule {
  final String id;
  String label;
  int startHour;
  int startMinute;
  int endHour;
  int endMinute;
  List<int> selectedDays; // 1=Mon … 7=Sun (ISO weekday)
  ScheduleRepeatMode repeatMode;
  SilentType silentType;
  bool isEnabled;
  DateTime createdAt;

  SilentSchedule({
    required this.id,
    required this.label,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    List<int>? selectedDays,
    this.repeatMode = ScheduleRepeatMode.daily,
    this.silentType = SilentType.silent,
    this.isEnabled = true,
    DateTime? createdAt,
  }) : selectedDays = selectedDays ?? [1, 2, 3, 4, 5, 6, 7],
       createdAt = createdAt ?? DateTime.now();

  // ── Active check ──────────────────────────────────────────────

  bool isActiveNow() {
    if (!isEnabled) return false;
    final now = DateTime.now();
    final currentDay = now.weekday; // 1‑Mon … 7‑Sun

    if (repeatMode == ScheduleRepeatMode.selectedDays &&
        !selectedDays.contains(currentDay)) {
      return false;
    }

    final currentMin = now.hour * 60 + now.minute;
    final startMin = startHour * 60 + startMinute;
    final endMin = endHour * 60 + endMinute;

    // handles overnight spans (e.g. 23:00 → 06:00)
    if (startMin <= endMin) {
      return currentMin >= startMin && currentMin < endMin;
    } else {
      return currentMin >= startMin || currentMin < endMin;
    }
  }

  // ── Formatting helpers ────────────────────────────────────────

  String get startTimeFormatted => _fmt(startHour, startMinute);
  String get endTimeFormatted => _fmt(endHour, endMinute);

  static String _fmt(int h, int m) {
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '${hour.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
  }

  String get daysDescription {
    if (repeatMode == ScheduleRepeatMode.daily) return 'Every day';
    if (repeatMode == ScheduleRepeatMode.once) return 'Once';
    if (selectedDays.length == 7) return 'Every day';
    if (selectedDays.length == 5 &&
        !selectedDays.contains(6) &&
        !selectedDays.contains(7)) {
      return 'Weekdays';
    }
    if (selectedDays.length == 2 &&
        selectedDays.contains(6) &&
        selectedDays.contains(7)) {
      return 'Weekends';
    }
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return selectedDays.map((d) => names[d - 1]).join(', ');
  }

  String get silentTypeLabel =>
      silentType == SilentType.silent ? 'Silent' : 'Vibrate';

  // ── Alarm IDs (positive 31‑bit ints) ──────────────────────────

  int get startAlarmId => ('${id}_start'.hashCode) & 0x7FFFFFFF;
  int get endAlarmId => ('${id}_end'.hashCode) & 0x7FFFFFFF;

  // ── JSON serialisation ────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'startHour': startHour,
    'startMinute': startMinute,
    'endHour': endHour,
    'endMinute': endMinute,
    'selectedDays': selectedDays,
    'repeatMode': repeatMode.index,
    'silentType': silentType.index,
    'isEnabled': isEnabled,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SilentSchedule.fromJson(Map<String, dynamic> json) => SilentSchedule(
    id: json['id'] as String,
    label: json['label'] as String,
    startHour: json['startHour'] as int,
    startMinute: json['startMinute'] as int,
    endHour: json['endHour'] as int,
    endMinute: json['endMinute'] as int,
    selectedDays: List<int>.from(json['selectedDays'] as List),
    repeatMode: ScheduleRepeatMode.values[json['repeatMode'] as int],
    silentType: SilentType.values[json['silentType'] as int],
    isEnabled: json['isEnabled'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  SilentSchedule copyWith({
    String? id,
    String? label,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    List<int>? selectedDays,
    ScheduleRepeatMode? repeatMode,
    SilentType? silentType,
    bool? isEnabled,
  }) {
    return SilentSchedule(
      id: id ?? this.id,
      label: label ?? this.label,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      selectedDays: selectedDays ?? List<int>.from(this.selectedDays),
      repeatMode: repeatMode ?? this.repeatMode,
      silentType: silentType ?? this.silentType,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt,
    );
  }

  // ── Prayer‑time presets ───────────────────────────────────────

  static List<SilentSchedule> get prayerPresets => [
    SilentSchedule(
      id: '',
      label: 'Fajr Prayer',
      startHour: 5,
      startMinute: 0,
      endHour: 6,
      endMinute: 0,
    ),
    SilentSchedule(
      id: '',
      label: 'Dhuhr Prayer',
      startHour: 12,
      startMinute: 30,
      endHour: 13,
      endMinute: 30,
    ),
    SilentSchedule(
      id: '',
      label: 'Asr Prayer',
      startHour: 15,
      startMinute: 30,
      endHour: 16,
      endMinute: 30,
    ),
    SilentSchedule(
      id: '',
      label: 'Maghrib Prayer',
      startHour: 18,
      startMinute: 15,
      endHour: 19,
      endMinute: 0,
    ),
    SilentSchedule(
      id: '',
      label: 'Isha Prayer',
      startHour: 20,
      startMinute: 0,
      endHour: 21,
      endMinute: 0,
    ),
  ];

  static List<SilentSchedule> get commonPresets => [
    SilentSchedule(
      id: '',
      label: 'Sleep Time',
      startHour: 23,
      startMinute: 0,
      endHour: 7,
      endMinute: 0,
    ),
    SilentSchedule(
      id: '',
      label: 'Meeting',
      startHour: 9,
      startMinute: 0,
      endHour: 10,
      endMinute: 0,
    ),
    SilentSchedule(
      id: '',
      label: 'Class / Lecture',
      startHour: 8,
      startMinute: 0,
      endHour: 9,
      endMinute: 30,
    ),
  ];
}
