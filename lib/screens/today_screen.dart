import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/day_key.dart';
import '../core/theme.dart';
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
        const SizedBox(height: 24),

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
