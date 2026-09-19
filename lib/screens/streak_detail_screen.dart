import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/models/habit_streak.dart';
import '../state/habit_streaks_state.dart';
import '../widgets/common.dart';

class StreakDetailScreen extends StatelessWidget {
  final int streakId;

  const StreakDetailScreen({super.key, required this.streakId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HabitStreaksState>();

    HabitStreak? streak;
    for (final s in state.streaks) {
      if (s.id == streakId) {
        streak = s;
        break;
      }
    }

    if (streak == null) {
      // Deleted from under us (e.g. via the button below) -- bail out
      // rather than render a stale/missing streak.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final s = streak;
    final milestones = s.milestoneDays;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(s.name.toUpperCase(), style: AppTheme.display(34)),
              ),
              CounterBadge(value: '${s.currentStreakFromDay1}', label: 'DAY\nSTREAK'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${s.monthLabel}  ·  Attempt ${s.attempt}',
            style: AppTheme.body(13.5, color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          Container(height: 3, color: AppColors.ink),
          const SizedBox(height: 22),

          Row(
            children: [
              _statBox('${s.currentStreakFromDay1}', 'CURRENT STREAK\n(FROM DAY 1)'),
              const SizedBox(width: 10),
              _statBox('${s.totalDone}', 'DAYS TICKED\nTOTAL'),
              const SizedBox(width: 10),
              _statBox('${s.days.length}', 'DAYS THIS\nMONTH'),
            ],
          ),
          const SizedBox(height: 22),

          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.95,
            children: [
              for (var i = 0; i < s.days.length; i++)
                _DayCell(
                  dayNumber: i + 1,
                  isDone: s.days[i],
                  isMilestone: milestones.contains(i + 1),
                  onTap: () => context.read<HabitStreaksState>().toggleDay(s.id, i + 1),
                ),
            ],
          ),

          const SizedBox(height: 18),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _legendItem(AppColors.accent, 'Ticked'),
              _legendItem(AppColors.paper2, 'Not yet', border: AppColors.ink),
              _legendItem(Colors.transparent, 'Milestone day', border: AppColors.gold),
            ],
          ),

          const SizedBox(height: 30),
          OutlinedButton(
            onPressed: () => _confirmDelete(context, s),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              'Delete this streak',
              style: AppTheme.body(13, color: AppColors.accent, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tap a box to tick or untick a day. The streak counts consecutive '
            'ticks starting from day 1.',
            textAlign: TextAlign.center,
            style: AppTheme.body(12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.paper2,
          border: Border.all(color: AppColors.ink, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTheme.display(28, color: AppColors.accent)),
            const SizedBox(height: 4),
            Text(label, style: AppTheme.body(10, color: AppColors.muted, weight: FontWeight.w700, height: 1.25)),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label, {Color? border}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: border ?? AppColors.muted, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTheme.body(11.5, color: AppColors.muted)),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, HabitStreak s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text('Delete "${s.name}"?', style: AppTheme.display(20)),
        content: Text(
          'This cannot be undone.',
          style: AppTheme.body(14, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Keep it', style: AppTheme.body(14, color: AppColors.ink)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: AppTheme.body(14, color: AppColors.accent, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await context.read<HabitStreaksState>().delete(s.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _DayCell extends StatelessWidget {
  final int dayNumber;
  final bool isDone;
  final bool isMilestone;
  final VoidCallback onTap;

  const _DayCell({
    required this.dayNumber,
    required this.isDone,
    required this.isMilestone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: isDone ? AppColors.accent : AppColors.paper2,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isMilestone ? AppColors.gold : (isDone ? AppColors.accent : AppColors.ink),
            width: isMilestone ? 2.2 : 1.5,
          ),
        ),
        padding: const EdgeInsets.all(6),
        child: Stack(
          children: [
            Text(
              '$dayNumber'.padLeft(2, '0'),
              style: AppTheme.body(
                11,
                color: isDone ? AppColors.accentTint : AppColors.muted,
                weight: FontWeight.w700,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? AppColors.accentTint : Colors.transparent,
                  border: Border.all(
                    color: isDone ? AppColors.accentTint : AppColors.muted,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}