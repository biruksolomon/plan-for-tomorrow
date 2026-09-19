import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/day_key.dart';
import '../core/theme.dart';
import '../data/models/day_plan.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class DayDetailScreen extends StatefulWidget {
  final String dayKey;

  const DayDetailScreen({super.key, required this.dayKey});

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  DayPlan? _plan;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plan = await context.read<AppState>().dayDetail(widget.dayKey);
    if (!mounted) return;
    setState(() => _plan = plan);
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: plan == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
              children: [
                PageMasthead(
                  title: _titleFor(plan),
                  subtitle: DayKey.pretty(plan.dayKey),
                  trailing: plan.hasPlan
                      ? CounterBadge(
                          value: '${plan.doneCount}',
                          label: 'OF ${plan.total}',
                        )
                      : null,
                ),
                const SizedBox(height: 24),
                if (!plan.hasPlan)
                  const EmptyNote(message: 'Nothing was planned for this day.')
                else ...[
                  for (var i = 0; i < plan.tasks.length; i++)
                    TickRow(
                      index: i + 1,
                      title: plan.tasks[i].title,
                      isDone: plan.tasks[i].isDone,
                      // No onToggle: the past is frozen and the future
                      // hasn't started.
                    ),
                  const SizedBox(height: 16),
                  Text(
                    _summaryFor(plan),
                    style: AppTheme.body(14, color: AppColors.muted),
                  ),
                ],
              ],
            ),
    );
  }

  String _titleFor(DayPlan plan) {
    switch (plan.phase) {
      case DayPhase.planning:
        return 'Planned';
      case DayPhase.active:
        return 'Today';
      case DayPhase.archived:
        return DayKey.shortPretty(plan.dayKey).split(' ').first;
    }
  }

  String _summaryFor(DayPlan plan) {
    if (plan.phase == DayPhase.planning) {
      return '${plan.total} task${plan.total == 1 ? '' : 's'} waiting for this day.';
    }
    if (plan.isPerfect) return 'Everything planned got done.';
    final missed = plan.total - plan.doneCount;
    return '$missed of ${plan.total} went unfinished.';
  }
}
