import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/day_key.dart';
import '../core/theme.dart';
import '../data/models/stats.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'plan_tomorrow_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final plan = state.today;

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 40),
      children: [
        PageMasthead(
          title: 'Today',
          subtitle: DayKey.pretty(DayKey.today()),
          trailing: plan.hasPlan
              ? CounterBadge(
                  value: '${plan.doneCount}',
                  label: 'OF ${plan.total}',
                )
              : null,
        ),
        const SizedBox(height: 20),
        _StreakBanner(stats: state.stats),

        if (!plan.hasPlan)
          EmptyNote(
            message:
                'Nothing was planned for today. Set tomorrow up tonight and '
                'it will be waiting here in the morning.',
            actionLabel: 'Plan tomorrow',
            onAction: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlanTomorrowScreen()),
            ),
          )
        else ...[
          for (var i = 0; i < plan.tasks.length; i++)
            TickRow(
              index: i + 1,
              title: plan.tasks[i].title,
              isDone: plan.tasks[i].isDone,
              onToggle: () => context.read<AppState>().toggle(plan.tasks[i].id!),
            ),
          const SizedBox(height: 10),
          _Progress(done: plan.doneCount, total: plan.total),
        ],

        if (plan.hasPlan && state.needsTomorrowPlan) ...[
          const SizedBox(height: 28),
          EmptyNote(
            message: 'Tomorrow is still blank.',
            actionLabel: 'Plan tomorrow',
            onAction: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlanTomorrowScreen()),
            ),
          ),
        ],

        const SizedBox(height: 30),
        const QuoteLine(
          'The list was decided last night. Today is only for doing it.',
        ),
      ],
    );
  }
}

class _StreakBanner extends StatelessWidget {
  final Stats stats;

  const _StreakBanner({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.currentStreak > 0) {
      return Padding(padding: const EdgeInsets.only(bottom: 20), child: _activeBanner());
    }
    if (stats.hasRecentBreak) {
      return Padding(padding: const EdgeInsets.only(bottom: 20), child: _breakNotice());
    }
    // No streak, no history to reference — nothing worth saying yet.
    return const SizedBox.shrink();
  }

  Widget _activeBanner() {
    final n = stats.currentStreak;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: AppColors.accentTint, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$n-day streak',
                  style: AppTheme.body(15.5, color: AppColors.accentTint, weight: FontWeight.w700),
                ),
                if (stats.isAtMilestone) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Longest run yet at this mark. Keep it going.',
                    style: AppTheme.body(12, color: AppColors.accentTint),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakNotice() {
    final day = DayKey.pretty(stats.streakBreakDay!);
    final missed = stats.streakBreakMissed ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        border: Border.all(color: AppColors.muted, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_outlined, color: AppColors.muted, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Streak ended — $missed task${missed == 1 ? '' : 's'} missed on $day. '
              'Today can start a new one.',
              style: AppTheme.body(13, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final int done;
  final int total;

  const _Progress({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : done / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: AppColors.paper2,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          done == total
              ? 'All done. Streak kept.'
              : '${total - done} left to finish today.',
          style: AppTheme.body(13, color: AppColors.muted),
        ),
      ],
    );
  }
}