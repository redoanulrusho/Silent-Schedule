import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';
import '../widgets/schedule_card.dart';
import 'add_edit_schedule_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh mode when user comes back to the app
      context.read<ScheduleProvider>().refreshCurrentMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Silent Schedule (developer RUSHO)',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () =>
                context.read<ScheduleProvider>().refreshCurrentMode(),
          ),
        ],
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              // ── Status card ──
              SliverToBoxAdapter(child: _StatusCard(provider: provider)),

              // ── DND permission banner (Android only) ──
              if (Platform.isAndroid && !provider.hasDndPermission)
                SliverToBoxAdapter(
                  child: _PermissionBanner(provider: provider),
                ),

              // ── iOS note ──
              if (Platform.isIOS) SliverToBoxAdapter(child: _IosNoteBanner()),

              // ── Schedule list or empty state ──
              if (provider.schedules.isEmpty)
                const SliverFillRemaining(child: _EmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  sliver: SliverList.builder(
                    itemCount: provider.schedules.length,
                    itemBuilder: (context, i) {
                      final s = provider.schedules[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ScheduleCard(
                          schedule: s,
                          onToggle: () => provider.toggleSchedule(s.id),
                          onTap: () => _openEditor(context, schedule: s),
                          onDelete: () => provider.deleteSchedule(s.id),
                        ),
                      );
                    },
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Schedule'),
      ),
    );
  }

  void _openEditor(BuildContext context, {dynamic schedule}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditScheduleScreen(existing: schedule),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub‑widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final ScheduleProvider provider;
  const _StatusCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final actives = provider.activeSchedules;
    final isActive = actives.isNotEmpty;

    IconData icon;
    String title;
    String subtitle;
    Color accent;

    if (isActive) {
      // Determine icon based on whether any schedule is fully silent
      final hasSilent = actives.any((s) => s.silentType == SilentType.silent);
      icon = hasSilent
          ? Icons.notifications_off_rounded
          : Icons.vibration_rounded;

      if (actives.length == 1) {
        title = actives.first.silentTypeLabel;
        subtitle =
            '${actives.first.label}  •  until ${actives.first.endTimeFormatted}';
      } else {
        title = '${actives.length} Schedules Active';
        final names = actives.map((s) => s.label).join(', ');
        subtitle = '$names  •  until ${provider.latestEndTime}';
      }
      accent = cs.primary;
    } else {
      icon = Icons.notifications_active_rounded;
      title = provider.currentMode;
      subtitle = '${provider.activeCount} schedule(s) enabled';
      accent = cs.tertiary;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Card(
        color: accent.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: accent.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 30, color: accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'ON',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: cs.onPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  final ScheduleProvider provider;
  const _PermissionBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: cs.errorContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: cs.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Do Not Disturb permission is required to change your phone\'s sound mode.',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onErrorContainer,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () => provider.requestDndPermission(),
                child: const Text('Grant'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IosNoteBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: cs.tertiaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: cs.onTertiaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'iOS does not allow apps to change the ringer mode. '
                  'You will receive a reminder notification instead.',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onTertiaryContainer,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_paused_rounded,
              size: 80,
              color: cs.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'No schedules yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to add your first\nsilent schedule for prayers, meetings, sleep & more.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.45),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
