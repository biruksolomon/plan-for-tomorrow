import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/models/habit_streak.dart';
import '../state/habit_streaks_state.dart';
import '../widgets/common.dart';
import 'new_streak_screen.dart';
import 'streak_detail_screen.dart';

class StreaksListScreen extends StatelessWidget {
  const StreaksListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HabitStreaksState>();

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 90),
      children: [
        PageMasthead(
          title: 'Streaks',
          subtitle: 'Each one is tied to a real month. Tick a day, watch the count go up.',
        ),
        const SizedBox(height: 22),
        if (state.streaks.isEmpty)
          EmptyNote(
            message: 'No streaks yet. Start one for anything you want to track '
                'day by day across a whole month.',
            actionLabel: 'New streak',
            onAction: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NewStreakScreen()),
            ),
          )
        else
          for (final s in state.streaks) _StreakCard(streak: s),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  final HabitStreak streak;

  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => StreakDetailScreen(streakId: streak.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.paper2,
          border: Border.all(color: AppColors.ink, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    streak.name,
                    style: AppTheme.body(15.5, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${streak.monthLabel}  ·  Attempt ${streak.attempt}',
                    style: AppTheme.body(12.5, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${streak.currentStreakFromDay1}',
                  style: AppTheme.display(28, color: AppColors.accent),
                ),
                Text(
                  'DAY STREAK',
                  style: AppTheme.body(10, color: AppColors.muted, weight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}