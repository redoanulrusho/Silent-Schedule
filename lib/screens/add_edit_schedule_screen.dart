import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';
import '../widgets/day_selector.dart';

class AddEditScheduleScreen extends StatefulWidget {
  final SilentSchedule? existing;
  const AddEditScheduleScreen({super.key, this.existing});

  @override
  State<AddEditScheduleScreen> createState() => _AddEditScheduleScreenState();
}

class _AddEditScheduleScreenState extends State<AddEditScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelCtrl;

  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late List<int> _selectedDays;
  late ScheduleRepeatMode _repeatMode;
  late SilentType _silentType;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _labelCtrl = TextEditingController(text: e?.label ?? '');
    _startTime = e != null
        ? TimeOfDay(hour: e.startHour, minute: e.startMinute)
        : const TimeOfDay(hour: 6, minute: 0);
    _endTime = e != null
        ? TimeOfDay(hour: e.endHour, minute: e.endMinute)
        : const TimeOfDay(hour: 7, minute: 0);
    _selectedDays = e?.selectedDays ?? [1, 2, 3, 4, 5, 6, 7];
    _repeatMode = e?.repeatMode ?? ScheduleRepeatMode.daily;
    _silentType = e?.silentType ?? SilentType.silent;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  // ── Save ────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ScheduleProvider>();
    final schedule = SilentSchedule(
      id: widget.existing?.id ?? const Uuid().v4(),
      label: _labelCtrl.text.trim(),
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      selectedDays: _selectedDays,
      repeatMode: _repeatMode,
      silentType: _silentType,
      isEnabled: widget.existing?.isEnabled ?? true,
      createdAt: widget.existing?.createdAt,
    );

    if (_isEditing) {
      await provider.updateSchedule(schedule);
    } else {
      await provider.addSchedule(schedule);
    }

    if (mounted) Navigator.pop(context);
  }

  // ── Time picker ─────────────────────────────────────────────────

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Schedule' : 'New Schedule'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Quick‑add presets (only for new schedules) ──
            if (!_isEditing) ...[
              Text(
                'Quick add',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              _PresetChips(
                onSelect: (preset) {
                  setState(() {
                    _labelCtrl.text = preset.label;
                    _startTime = TimeOfDay(
                      hour: preset.startHour,
                      minute: preset.startMinute,
                    );
                    _endTime = TimeOfDay(
                      hour: preset.endHour,
                      minute: preset.endMinute,
                    );
                  });
                },
              ),
              const SizedBox(height: 24),
            ],

            // ── Label ──
            TextFormField(
              controller: _labelCtrl,
              decoration: InputDecoration(
                labelText: 'Schedule Name',
                hintText: 'e.g. Fajr Prayer, Meeting…',
                prefixIcon: const Icon(Icons.label_outline_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 24),

            // ── Time pickers ──
            Text(
              'Time',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TimeTile(
                    label: 'Start',
                    time: _startTime,
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                Expanded(
                  child: _TimeTile(
                    label: 'End',
                    time: _endTime,
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Repeat mode ──
            Text(
              'Repeat',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<ScheduleRepeatMode>(
              segments: const [
                ButtonSegment(
                  value: ScheduleRepeatMode.daily,
                  label: Text('Daily'),
                  icon: Icon(Icons.repeat_rounded),
                ),
                ButtonSegment(
                  value: ScheduleRepeatMode.selectedDays,
                  label: Text('Custom'),
                  icon: Icon(Icons.calendar_view_week_rounded),
                ),
                ButtonSegment(
                  value: ScheduleRepeatMode.once,
                  label: Text('Once'),
                  icon: Icon(Icons.looks_one_rounded),
                ),
              ],
              selected: {_repeatMode},
              onSelectionChanged: (v) => setState(() => _repeatMode = v.first),
            ),
            const SizedBox(height: 16),

            // ── Day selector (only for "Custom") ──
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _repeatMode == ScheduleRepeatMode.selectedDays
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DaySelector(
                        selectedDays: _selectedDays,
                        onChanged: (d) => setState(() => _selectedDays = d),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // ── Silent type ──
            Text(
              'Mode',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<SilentType>(
              segments: const [
                ButtonSegment(
                  value: SilentType.silent,
                  label: Text('Silent'),
                  icon: Icon(Icons.notifications_off_rounded),
                ),
                ButtonSegment(
                  value: SilentType.vibrate,
                  label: Text('Vibrate'),
                  icon: Icon(Icons.vibration_rounded),
                ),
              ],
              selected: {_silentType},
              onSelectionChanged: (v) => setState(() => _silentType = v.first),
            ),

            const SizedBox(height: 36),

            // ── Save button ──
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(_isEditing ? Icons.check_rounded : Icons.add_rounded),
              label: Text(_isEditing ? 'Update Schedule' : 'Save Schedule'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _TimeTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final display =
        '${h.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              display,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChips extends StatelessWidget {
  final void Function(SilentSchedule) onSelect;
  const _PresetChips({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final all = [
      ...SilentSchedule.prayerPresets,
      ...SilentSchedule.commonPresets,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: all.map((p) {
        final isPrayer = p.label.contains('Prayer');
        return ActionChip(
          avatar: Icon(
            isPrayer ? Icons.mosque_rounded : Icons.schedule_rounded,
            size: 18,
          ),
          label: Text(p.label),
          onPressed: () => onSelect(p),
        );
      }).toList(),
    );
  }
}
