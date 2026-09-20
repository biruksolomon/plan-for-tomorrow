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

    // These queries fire on every keystroke and can resolve out of order --
    // typing fast enough means the request for "R" can come back *after*
    // the request for "Reading" and silently overwrite the correct number
    // with a stale one. Only apply a result if the name it was asked about
    // is still what's actually in the field right now.
    if (_nameController.text.trim() != name) return;

    _attemptController.text = '$suggestion';
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DayKey.parse(_startDate),
      // The whole point: you can backdate to say you'd already started,
      // but you can never pick a date that hasn't happened yet.
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'When did you actually start?',
    );
    if (picked == null) return;
    setState(() => _startDate = DayKey.of(picked));
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
          _label('Streak name'),
          _textField(
            controller: _nameController,
            hint: 'e.g. Morning workout',
            onChanged: (_) => setState(() {}),
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
