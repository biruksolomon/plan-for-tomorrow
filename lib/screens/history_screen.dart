import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/day_key.dart';
import '../core/theme.dart';
import '../data/models/stats.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'day_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime _month;
  List<DailyPoint> _points = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final pts = await context.read<AppState>().monthPoints(_month);
    if (!mounted) return;
    setState(() {
      _points = pts;
      _loading = false;
    });
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
    _load();
  }

  /// Don't let the user page into months that haven't happened.
  bool get _canGoForward {
    final now = DateTime.now();
    return _month.isBefore(DateTime(now.year, now.month));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 40),
      children: [
        PageMasthead(
          title: 'History',
          subtitle: 'Every day you planned, and how much of it you did.',
        ),
        const SizedBox(height: 22),
        _monthBar(),
        const SizedBox(height: 18),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          )
        else ...[
          _weekdayHeader(),
          const SizedBox(height: 8),
          _calendar(),
          const SizedBox(height: 24),
          _legend(),
        ],
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
          DateFormat('MMMM yyyy').format(_month).toUpperCase(),
          style: AppTheme.display(24),
        ),
        IconButton(
          onPressed: _canGoForward ? () => _shiftMonth(1) : null,
          icon: Icon(
            Icons.chevron_right,
            color: _canGoForward ? AppColors.ink : AppColors.muted.withValues(alpha: 0.4),
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
                  child: Text(
                    l,
                    style: AppTheme.body(
                      12,
                      color: AppColors.muted,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _calendar() {
    final first = DateTime(_month.year, _month.month, 1);
    // DateTime.weekday is 1=Mon, and the grid starts on Monday.
    final leading = first.weekday - 1;
    final cells = <Widget>[
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (final p in _points) _dayCell(p),
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

  Widget _dayCell(DailyPoint p) {
    final date = DayKey.parse(p.dayKey);
    final isToday = p.dayKey == DayKey.today();
    final isFuture = DayKey.daysBetween(DayKey.today(), p.dayKey) > 0;
    final rate = p.rate;

    Color bg;
    Color fg;
    if (!p.hasPlan) {
      bg = Colors.transparent;
      fg = AppColors.muted;
    } else if (rate == 1.0) {
      bg = AppColors.accent;
      fg = AppColors.accentTint;
    } else if (rate! > 0) {
      // Partial days read as a lighter wash of the same red, so the month
      // reads as a gradient of effort rather than pass/fail.
      bg = Color.lerp(AppColors.paper2, AppColors.accent, rate)!;
      fg = rate > 0.5 ? AppColors.accentTint : AppColors.ink;
    } else {
      bg = AppColors.paper2;
      fg = AppColors.muted;
    }

    return GestureDetector(
      onTap: p.hasPlan
          ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DayDetailScreen(dayKey: p.dayKey),
                ),
              )
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isToday
                ? AppColors.ink
                : (isFuture ? AppColors.gold : AppColors.muted.withValues(alpha: 0.5)),
            width: isToday ? 2.2 : 1,
          ),
        ),
        child: Center(
          child: Text('${date.day}', style: AppTheme.body(13, color: fg, weight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _legend() {
    Widget swatch(Color c, String label, {Color? border}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: border ?? AppColors.muted, width: 1),
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: AppTheme.body(11.5, color: AppColors.muted)),
          ],
        );

    return Wrap(
      spacing: 16,
      runSpacing: 10,
      children: [
        swatch(AppColors.accent, 'All done'),
        swatch(Color.lerp(AppColors.paper2, AppColors.accent, 0.5)!, 'Partly done'),
        swatch(AppColors.paper2, 'Nothing done'),
        swatch(Colors.transparent, 'No plan'),
        swatch(Colors.transparent, 'Planned ahead', border: AppColors.gold),
      ],
    );
  }
}
