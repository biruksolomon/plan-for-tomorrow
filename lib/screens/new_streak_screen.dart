import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/day_key.dart';
import '../core/theme.dart';
import '../state/habit_streaks_state.dart';
import '../widgets/common.dart';
import 'streak_detail_screen.dart';

class NewStreakScreen extends StatefulWidget {
  const NewStreakScreen({super.key});

  @override
  State<NewStreakScreen> createState() => _NewStreakScreenState();
}

class _NewStreakScreenState extends State<NewStreakScreen> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController(text: '30');
  final _attemptController = TextEditingController(text: '1');

  late String
      _startDate; // defaults to today; can only be backdated, never future
  String _category = 'positive'; // 'positive' or 'recovery'
  TimeOfDay? _reminderTime;
  TimeOfDay? _highRiskStart;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _startDate = DayKey.today();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _targetController.dispose();
    _attemptController.dispose();
    super.dispose();
  }

  Future<void> _onNameChanged() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final suggestion =
        await context.read<HabitStreaksState>().suggestNextAttempt(name);
    if (!mounted) return;

    if (_nameController.text.trim() != name) return;

    _attemptController.text = '$suggestion';
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DayKey.parse(_startDate),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'When did you actually start?',
    );
    if (picked == null) return;
    setState(() => _startDate = DayKey.of(picked));
  }

  String _formatTimeOfDay(TimeOfDay? t) {
    if (t == null) return 'Not set';
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    final target = int.tryParse(_targetController.text) ?? 30;
    final attempt = int.tryParse(_attemptController.text) ?? 1;

    final created = await context.read<HabitStreaksState>().create(
          name: name,
          startDate: _startDate,
          targetLength: target < 1 ? 1 : target,
          attempt: attempt,
          category: _category,
          reminderTime: _reminderTime != null ? _formatTimeOfDay(_reminderTime) : null,
          highRiskStart: _highRiskStart != null ? _formatTimeOfDay(_highRiskStart) : null,
        );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          builder: (_) => StreakDetailScreen(streakId: created.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = _nameController.text.trim().isNotEmpty && !_saving;
    final isBackdated = _startDate != DayKey.today();

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
          Text('NEW STREAK', style: AppTheme.display(40)),
          const SizedBox(height: 4),
          Container(
              height: 3,
              color: AppColors.ink,
              margin: const EdgeInsets.only(top: 14, bottom: 26)),
          _label('Category'),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _category = 'positive'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _category == 'positive' ? AppColors.accent : AppColors.paper2,
                      border: Border.all(color: AppColors.ink, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Positive Habit',
                        style: AppTheme.body(13,
                            weight: FontWeight.w700,
                            color: _category == 'positive' ? AppColors.accentTint : AppColors.ink),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _category = 'recovery'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _category == 'recovery' ? AppColors.accent : AppColors.paper2,
                      border: Border.all(color: AppColors.ink, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Quit / Recovery',
                        style: AppTheme.body(13,
                            weight: FontWeight.w700,
                            color: _category == 'recovery' ? AppColors.accentTint : AppColors.ink),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _label('Streak name'),
          _textField(
            controller: _nameController,
            hint: _category == 'recovery' ? 'e.g. No PMO / Clean Streak' : 'e.g. Morning workout',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          _label('Daily Reminder Time (Optional)'),
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _reminderTime ?? const TimeOfDay(hour: 20, minute: 0),
              );
              if (picked != null) setState(() => _reminderTime = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.paper2,
                border: Border.all(color: AppColors.ink, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _reminderTime == null ? 'No daily alarm set' : 'Alarm set at ${_formatTimeOfDay(_reminderTime)}',
                      style: AppTheme.body(14, weight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.access_time, size: 17, color: AppColors.muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _label('Start date'),
          GestureDetector(
            onTap: _pickStartDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.paper2,
                border: Border.all(color: AppColors.ink, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DayKey.pretty(_startDate),
                      style: AppTheme.body(15, weight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.calendar_today,
                      size: 17, color: AppColors.muted),
                ],
              ),
            ),
          ),
          if (isBackdated) ...[
            const SizedBox(height: 8),
            Text(
              'Day 1 is ${DayKey.pretty(_startDate)}. Every day up to today counts as '
              'already elapsed -- nothing is locked out.',
              style: AppTheme.body(12,
                  color: AppColors.gold, weight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Target (days)'),
                    _textField(
                      controller: _targetController,
                      hint: '30',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Attempt no.'),
                    _textField(
                      controller: _attemptController,
                      hint: '1',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          PrimaryButton(
            label: _saving ? 'Creating…' : 'Create streak',
            onPressed: canCreate ? _create : null,
          ),
          const SizedBox(height: 12),
          Text(
            'Future days are always locked, no matter what you pick here -- '
            'you can only ever tick up to today.',
            textAlign: TextAlign.center,
            style: AppTheme.body(12.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text.toUpperCase(),
          style: AppTheme.body(11.5,
              color: AppColors.muted, weight: FontWeight.w700),
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper2,
        border: Border.all(color: AppColors.ink, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: AppTheme.body(15, weight: FontWeight.w600),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          hintText: hint,
          hintStyle: AppTheme.body(15, color: AppColors.muted),
        ),
      ),
    );
  }
}
