import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/models/habit_streak.dart';
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
  final _attemptController = TextEditingController(text: '1');

  late int _month;
  late int _year;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _attemptController.dispose();
    super.dispose();
  }

  Future<void> _onNameChanged() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final suggestion = await context.read<HabitStreaksState>().suggestNextAttempt(name);
    if (!mounted) return;
    _attemptController.text = '$suggestion';
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    final attempt = int.tryParse(_attemptController.text) ?? 1;
    final created = await context.read<HabitStreaksState>().create(
          name: name,
          month: _month,
          year: _year,
          attempt: attempt,
        );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => StreakDetailScreen(streakId: created.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = _nameController.text.trim().isNotEmpty && !_saving;

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
          Container(height: 3, color: AppColors.ink, margin: const EdgeInsets.only(top: 14, bottom: 26)),

          _label('Streak name'),
          _textField(
            controller: _nameController,
            hint: 'e.g. Morning workout',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Month'),
                    _monthDropdown(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Year'),
                    _yearDropdown(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _label('Attempt no.'),
          _textField(
            controller: _attemptController,
            hint: '1',
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 26),
          PrimaryButton(
            label: _saving ? 'Creating…' : 'Create streak',
            onPressed: canCreate ? _create : null,
          ),
          const SizedBox(height: 12),
          Text(
            'Attempt number fills in automatically if you\'ve used this name '
            'before — change it if you want.',
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
          style: AppTheme.body(11.5, color: AppColors.muted, weight: FontWeight.w700),
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

  Widget _monthDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper2,
        border: Border.all(color: AppColors.ink, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _month,
          isExpanded: true,
          style: AppTheme.body(15, weight: FontWeight.w600),
          dropdownColor: AppColors.paper2,
          items: [
            for (var m = 1; m <= 12; m++)
              DropdownMenuItem(value: m, child: Text(HabitStreak.monthNames[m - 1])),
          ],
          onChanged: (v) => setState(() => _month = v!),
        ),
      ),
    );
  }

  Widget _yearDropdown() {
    final now = DateTime.now().year;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper2,
        border: Border.all(color: AppColors.ink, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _year,
          isExpanded: true,
          style: AppTheme.body(15, weight: FontWeight.w600),
          dropdownColor: AppColors.paper2,
          // One year back covers a streak someone starts logging late;
          // one year forward covers planning ahead.
          items: [
            for (var y = now - 1; y <= now + 1; y++)
              DropdownMenuItem(value: y, child: Text('$y')),
          ],
          onChanged: (v) => setState(() => _year = v!),
        ),
      ),
    );
  }
}