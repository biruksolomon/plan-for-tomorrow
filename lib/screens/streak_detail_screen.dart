import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/day_key.dart';
import '../core/theme.dart';
import '../data/models/habit_streak.dart';
import '../state/habit_streaks_state.dart';
import '../widgets/common.dart';

enum _Pen { tick, missed }

class StreakDetailScreen extends StatefulWidget {
  final int streakId;

  const StreakDetailScreen({super.key, required this.streakId});

  @override
  State<StreakDetailScreen> createState() => _StreakDetailScreenState();
}

class _StreakDetailScreenState extends State<StreakDetailScreen> {
  late DateTime _viewMonth;
  _Pen _pen = _Pen.tick;

  @override
  void initState() {
    super.initState();
    // Always opens on today's month -- "today is the 20th" means the
    // person expects to see this month, not the month the streak started
    // in (those can differ once a streak runs long enough).
    final now = DateTime.now();
    _viewMonth = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(
        () => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta));
  }

  /// No reason to page into a month that hasn't started -- everything in
  /// it would be locked anyway.
  bool get _canGoForward {
    final now = DateTime.now();
    return _viewMonth.isBefore(DateTime(now.year, now.month));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HabitStreaksState>();

    HabitStreak? streak;
    for (final s in state.streaks) {
      if (s.id == widget.streakId) {
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
    // Real dates, computed once per build -- the milestone *count* (7/14/
    // 21/target) still comes from the streak's own day-1..N math, but each
    // one is converted to the actual date it falls on so it can be found
    // and highlighted no matter which month is currently on screen.
    final milestoneDates = {for (final m in s.milestoneDays) s.dayKeyFor(m)};

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
              CounterBadge(
                  value: '${s.currentStreakFromStart}', label: 'DAY\nSTREAK'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Started ${DayKey.pretty(s.startDate)}  ·  Attempt ${s.attempt}',
            style: AppTheme.body(13.5, color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          Container(height: 3, color: AppColors.ink),
          const SizedBox(height: 22),
          Row(
            children: [
              _statBox('${s.currentStreakFromStart}',
                  'CURRENT STREAK\n(FROM DAY 1)'),
              const SizedBox(width: 10),
              _statBox('${s.totalDone}', 'DAYS DONE\nTOTAL'),
              const SizedBox(width: 10),
              _statBox('${s.totalMissed}', 'DAYS MISSED\nTOTAL'),
            ],
          ),
          const SizedBox(height: 22),
          _penSelector(),
          const SizedBox(height: 20),
          _monthBar(),
          const SizedBox(height: 14),
          _weekdayHeader(),
          const SizedBox(height: 8),
          _calendar(s, milestoneDates),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _legendItem(AppColors.accent, 'Done'),
              _legendItem(AppColors.paper2, 'Missed',
                  border: AppColors.accent, marker: '✕'),
              _legendItem(AppColors.paper2, 'Blank', border: AppColors.ink),
              _legendItem(AppColors.paper, 'Locked', border: AppColors.muted),
              _legendItem(Colors.transparent, 'Milestone',
                  border: AppColors.gold),
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
              style: AppTheme.body(13,
                  color: AppColors.accent, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Pick a pen above, then tap any day up to today. Marking a day '
            'missed asks why -- tap it again with Missed selected to clear it.',
            textAlign: TextAlign.center,
            style: AppTheme.body(12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _penSelector() {
    Widget btn(_Pen p, String label, IconData icon) {
      final active = _pen == p;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _pen = p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: active ? AppColors.accent : AppColors.paper2,
              border: Border.all(
                  color: active ? AppColors.accent : AppColors.ink, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 16,
                    color: active ? AppColors.accentTint : AppColors.ink),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTheme.body(
                    13,
                    weight: FontWeight.w700,
                    color: active ? AppColors.accentTint : AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        btn(_Pen.tick, 'Tick', Icons.check),
        const SizedBox(width: 10),
        btn(_Pen.missed, 'Missed', Icons.close),
      ],
    );
  }

  Widget _monthBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _shiftMonth(-1),
          icon: const Icon(Icons.chevron_left, color: AppColors.ink),
        ),
        Text(
          DateFormat('MMMM yyyy').format(_viewMonth).toUpperCase(),
          style: AppTheme.display(22),
        ),
        IconButton(
          onPressed: _canGoForward ? () => _shiftMonth(1) : null,
          icon: Icon(
            Icons.chevron_right,
            color: _canGoForward
                ? AppColors.ink
                : AppColors.muted.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  Widget _weekdayHeader() {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      children: labels
          .map((l) => Expanded(
                child: Center(
                  child: Text(l,
                      style: AppTheme.body(12,
                          color: AppColors.muted, weight: FontWeight.w700)),
                ),
              ))
          .toList(),
    );
  }

  Widget _calendar(HabitStreak s, Set<String> milestoneDates) {
    final first = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    // DateTime.weekday is 1=Mon, and the grid starts on Monday.
    final leading = first.weekday - 1;

    final cells = <Widget>[
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var d = 1; d <= daysInMonth; d++)
        _dayCell(
            s, DateTime(_viewMonth.year, _viewMonth.month, d), milestoneDates),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: cells,
    );
  }

  Widget _dayCell(HabitStreak s, DateTime date, Set<String> milestoneDates) {
    final key = DayKey.of(date);
    // The only lock is the future. A day being before the streak's own
    // start date does not block it -- see the model's doc comment.
    final locked = s.isFuture(key);
    final done = s.isDoneOn(key);
    final missed = s.isMissedOn(key);
    final isMilestone = milestoneDates.contains(key);
    final isToday = key == DayKey.today();

    Color bg;
    Color borderColor;
    Color textColor;
    if (done) {
      bg = AppColors.accent;
      borderColor = AppColors.accent;
      textColor = AppColors.accentTint;
    } else if (missed) {
      bg = AppColors.paper2;
      borderColor = AppColors.accent;
      textColor = AppColors.accent;
    } else if (locked) {
      bg = AppColors.paper;
      borderColor = AppColors.muted.withValues(alpha: 0.35);
      textColor = AppColors.muted.withValues(alpha: 0.45);
    } else {
      bg = AppColors.paper2;
      borderColor = AppColors.ink;
      textColor = AppColors.ink;
    }
    if (isMilestone) borderColor = AppColors.gold;

    return GestureDetector(
      onTap: locked ? null : () => _handleTap(s, key, done, missed),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isToday ? AppColors.ink : borderColor,
            width: isToday ? 2.2 : (isMilestone ? 2 : 1),
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Text('${date.day}',
                  style: AppTheme.body(13,
                      color: textColor, weight: FontWeight.w600)),
            ),
            if (missed)
              const Positioned(
                right: 3,
                bottom: 1,
                child: Icon(Icons.close, size: 12, color: AppColors.accent),
              )
            else if (locked)
              const Positioned(
                right: 3,
                bottom: 2,
                child:
                    Icon(Icons.lock_outline, size: 11, color: AppColors.muted),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTap(
      HabitStreak s, String dayKey, bool wasDone, bool wasMissed) async {
    final streaksState = context.read<HabitStreaksState>();

    if (_pen == _Pen.tick) {
      // A direct "set to done"; tapping an already-done day clears it back
      // to blank. Switching pens and tapping a missed day overwrites it
      // (its reason is discarded, same as picking a new answer).
      if (wasDone) {
        await streaksState.clearDay(s.id, dayKey);
      } else {
        await streaksState.markDone(s.id, dayKey);
      }
      return;
    }

    // Missed pen.
    if (wasMissed) {
      await streaksState.clearDay(s.id, dayKey);
      return;
    }
    final reason = await _askReason(context);
    if (reason == null) return; // cancelled -- day stays exactly as it was
    await streaksState.markMissed(s.id, dayKey, reason);
  }

  Future<String?> _askReason(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final canSave = controller.text.trim().isNotEmpty;
          return AlertDialog(
            backgroundColor: AppColors.paper,
            title:
                Text('Why was this day missed?', style: AppTheme.display(20)),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              maxLength: 140,
              onChanged: (_) => setDialogState(() {}),
              style: AppTheme.body(14),
              decoration: InputDecoration(
                hintText: 'A reason is required to mark this day missed',
                hintStyle: AppTheme.body(13, color: AppColors.muted),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.ink),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: Text('Cancel',
                    style: AppTheme.body(14, color: AppColors.ink)),
              ),
              TextButton(
                onPressed: canSave
                    ? () => Navigator.of(ctx).pop(controller.text.trim())
                    : null,
                child: Text(
                  'Save',
                  style: AppTheme.body(
                    14,
                    weight: FontWeight.w700,
                    color: canSave ? AppColors.accent : AppColors.muted,
                  ),
                ),
              ),
            ],
          );
        },
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
            Text(value, style: AppTheme.display(24, color: AppColors.accent)),
            const SizedBox(height: 4),
            Text(label,
                style: AppTheme.body(10,
                    color: AppColors.muted,
                    weight: FontWeight.w700,
                    height: 1.25)),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label,
      {Color? border, String? marker}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: border ?? AppColors.muted, width: 1.5),
          ),
          child: marker == null
              ? null
              : Text(marker,
                  style: TextStyle(fontSize: 8, color: border, height: 1)),
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
        content: Text('This cannot be undone.',
            style: AppTheme.body(14, color: AppColors.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:
                Text('Keep it', style: AppTheme.body(14, color: AppColors.ink)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete',
                style: AppTheme.body(14,
                    color: AppColors.accent, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await context.read<HabitStreaksState>().delete(s.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}
