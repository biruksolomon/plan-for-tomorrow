import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/day_key.dart';
import '../core/theme.dart';
import '../data/repositories/task_repository.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class PlanTomorrowScreen extends StatefulWidget {
  const PlanTomorrowScreen({super.key});

  @override
  State<PlanTomorrowScreen> createState() => _PlanTomorrowScreenState();
}

class _PlanTomorrowScreenState extends State<PlanTomorrowScreen> {
  static const _max = TaskRepository.maxTasksPerDay;

  late final List<TextEditingController> _controllers;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    // Pre-fill with whatever is already planned so reopening the screen
    // edits the existing plan instead of silently starting over.
    final existing = context.read<AppState>().tomorrow.tasks;
    _controllers = List.generate(
      _max,
      (i) => TextEditingController(
        text: i < existing.length ? existing[i].title : '',
      ),
    );

    for (final c in _controllers) {
      c.addListener(_onChanged);
    }
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    for (final c in _controllers) {
      c.removeListener(_onChanged);
      c.dispose();
    }
    super.dispose();
  }

  int get _filled =>
      _controllers.where((c) => c.text.trim().isNotEmpty).length;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context
          .read<AppState>()
          .saveTomorrow(_controllers.map((c) => c.text).toList());
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          content: Text(
            'Locked in for tomorrow.',
            style: AppTheme.body(14, color: AppColors.paper),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.accent,
          content: Text(
            'Could not save the plan. $e',
            style: AppTheme.body(14, color: AppColors.accentTint),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          PageMasthead(
            title: 'Tomorrow',
            subtitle: DayKey.pretty(DayKey.tomorrow()),
            trailing: CounterBadge(value: '$_filled', label: 'OF $_max'),
          ),
          const SizedBox(height: 10),
          Text(
            'Write what tomorrow is for. Once the day starts this list is '
            'fixed — you will only be able to tick it off.',
            style: AppTheme.body(14, color: AppColors.muted),
          ),
          const SizedBox(height: 22),

          for (var i = 0; i < _max; i++) _field(i),

          const SizedBox(height: 18),
          PrimaryButton(
            label: _saving ? 'Saving…' : 'Lock in for tomorrow',
            onPressed: (_filled == 0 || _saving) ? null : _save,
          ),
          const SizedBox(height: 12),
          Text(
            _filled == 0
                ? 'Add at least one task to lock the day in.'
                : 'You can keep editing this until midnight.',
            textAlign: TextAlign.center,
            style: AppTheme.body(12.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _field(int i) {
    final hasText = _controllers[i].text.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        border: Border.all(
          color: hasText ? AppColors.ink : AppColors.muted,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              (i + 1).toString().padLeft(2, '0'),
              style: AppTheme.display(
                18,
                color: hasText ? AppColors.accent : AppColors.muted,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controllers[i],
              textCapitalization: TextCapitalization.sentences,
              textInputAction:
                  i == _max - 1 ? TextInputAction.done : TextInputAction.next,
              maxLength: 80,
              style: AppTheme.body(15, weight: FontWeight.w600),
              decoration: InputDecoration(
                counterText: '',
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                hintText: 'Task ${i + 1}',
                hintStyle: AppTheme.body(15, color: AppColors.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
