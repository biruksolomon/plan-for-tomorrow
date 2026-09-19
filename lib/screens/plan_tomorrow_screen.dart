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

/// One row's editing state. A GlobalKey per row would work too, but a plain
/// controller list keyed by a stable id is simpler to reason about when rows
/// are inserted/removed from the middle.
class _Row {
  final int id;
  final TextEditingController controller;
  final FocusNode focusNode;

  _Row(this.id, {String text = ''})
      : controller = TextEditingController(text: text),
        focusNode = FocusNode();

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

class _PlanTomorrowScreenState extends State<PlanTomorrowScreen> {
  static const _max = TaskRepository.maxTasksPerDay;

  final List<_Row> _rows = [];
  int _nextId = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    // Pre-fill with whatever is already planned. If nothing is planned yet,
    // start with 3 blank rows rather than 1 — enough to write without
    // reaching for the add button immediately, but nowhere near the cap.
    final existing = context.read<AppState>().tomorrow.tasks;
    if (existing.isEmpty) {
      for (var i = 0; i < 3; i++) {
        _rows.add(_Row(_nextId++));
      }
    } else {
      for (final task in existing) {
        _rows.add(_Row(_nextId++, text: task.title));
      }
    }

    for (final row in _rows) {
      row.controller.addListener(_onChanged);
    }
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    for (final row in _rows) {
      row.controller.removeListener(_onChanged);
      row.dispose();
    }
    super.dispose();
  }

  bool get _atMax => _rows.length >= _max;

  int get _filled =>
      _rows.where((r) => r.controller.text.trim().isNotEmpty).length;

  void _addRow() {
    if (_atMax) return;
    setState(() {
      final row = _Row(_nextId++);
      row.controller.addListener(_onChanged);
      _rows.add(row);
    });
    // Focus the row that was just added, one frame after it's laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _rows.isNotEmpty) _rows.last.focusNode.requestFocus();
    });
  }

  void _removeRow(int id) {
    setState(() {
      final row = _rows.firstWhere((r) => r.id == id);
      row.controller.removeListener(_onChanged);
      row.dispose();
      _rows.removeWhere((r) => r.id == id);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context
          .read<AppState>()
          .saveTomorrow(_rows.map((r) => r.controller.text).toList());
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
            trailing: CounterBadge(value: '${_rows.length}', label: 'OF $_max'),
          ),
          const SizedBox(height: 10),
          Text(
            'Write what tomorrow is for. Once the day starts this list is '
            'fixed — you will only be able to tick it off.',
            style: AppTheme.body(14, color: AppColors.muted),
          ),
          const SizedBox(height: 22),

          for (var i = 0; i < _rows.length; i++) _field(i),

          const SizedBox(height: 4),
          _addButton(),

          const SizedBox(height: 22),
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
    final row = _rows[i];
    final hasText = row.controller.text.trim().isNotEmpty;
    // Only offer removal once there's more than one row, so the user is
    // never left staring at zero fields with no way back in.
    final canRemove = _rows.length > 1;

    return Container(
      key: ValueKey(row.id),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              controller: row.controller,
              focusNode: row.focusNode,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: i == _rows.length - 1
                  ? TextInputAction.done
                  : TextInputAction.next,
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
          SizedBox(
            width: 36,
            child: canRemove
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
                    onPressed: () => _removeRow(row.id),
                    tooltip: 'Remove task',
                    padding: EdgeInsets.zero,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _addButton() {
    if (_atMax) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'That\'s the limit for one day — $_max tasks keeps the list honest.',
          textAlign: TextAlign.center,
          style: AppTheme.body(12.5, color: AppColors.muted),
        ),
      );
    }

    return InkWell(
      onTap: _addRow,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.muted, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 18, color: AppColors.muted),
            const SizedBox(width: 8),
            Text(
              'Add task',
              style: AppTheme.body(14, color: AppColors.muted, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}