import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/models/stats.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  static const _weekdayNames = {
    1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun',
  };

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<AppState>().stats;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 40),
      children: [
        PageMasthead(
          title: 'Record',
          subtitle: 'What the last few weeks actually look like.',
        ),
        const SizedBox(height: 24),

        if (!stats.hasData)
          const EmptyNote(
            message:
                'No finished days yet. Plan a day, tick it off, and the '
                'numbers start here.',
          )
        else ...[
          _streakRow(stats),
          const SizedBox(height: 26),
          _sectionTitle('Last 30 days'),
          const SizedBox(height: 14),
          _TrendChart(points: stats.recentDays),
          const SizedBox(height: 28),
          _sectionTitle('By day of week'),
          const SizedBox(height: 14),
          _WeekdayBars(byWeekday: stats.byWeekday),
          const SizedBox(height: 20),
          _insight(stats),
          const SizedBox(height: 26),
          _sectionTitle('Totals'),
          const SizedBox(height: 12),
          _totals(stats),
        ],
      ],
    );
  }

  Widget _sectionTitle(String text) => Text(text, style: AppTheme.display(22));

  Widget _streakRow(Stats s) {
    return Row(
      children: [
        Expanded(
          child: _StatBlock(
            value: '${s.currentStreak}',
            label: 'Current streak',
            unit: s.currentStreak == 1 ? 'day' : 'days',
            emphasised: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBlock(
            value: '${s.bestStreak}',
            label: 'Best streak',
            unit: s.bestStreak == 1 ? 'day' : 'days',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBlock(
            value: s.recentRate == null
                ? '—'
                : '${(s.recentRate! * 100).round()}%',
            label: 'Done, 30d',
          ),
        ),
      ],
    );
  }

  Widget _insight(Stats s) {
    final best = s.bestWeekday;
    final worst = s.worstWeekday;
    if (best == null || worst == null || best == worst) {
      return const SizedBox.shrink();
    }

    final bestPct = (s.byWeekday[best]! * 100).round();
    final worstPct = (s.byWeekday[worst]! * 100).round();

    return QuoteLine(
      '${_weekdayNames[best]} is your strongest day at $bestPct%. '
      '${_weekdayNames[worst]} is where it slips, at $worstPct%. '
      'Plan a lighter list for ${_weekdayNames[worst]}.',
    );
  }

  Widget _totals(Stats s) {
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTheme.body(14, color: AppColors.muted)),
              Text(value, style: AppTheme.body(14, weight: FontWeight.w700)),
            ],
          ),
        );

    return Column(
      children: [
        row('Days planned', '${s.daysPlanned}'),
        const Divider(height: 1, color: AppColors.paper2),
        row('Days fully cleared', '${s.perfectDays}'),
        const Divider(height: 1, color: AppColors.paper2),
        row('Tasks done', '${s.tasksDone} of ${s.tasksPlanned}'),
        const Divider(height: 1, color: AppColors.paper2),
        row(
          'All-time completion',
          s.overallRate == null ? '—' : '${(s.overallRate! * 100).round()}%',
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  final String? unit;
  final bool emphasised;

  const _StatBlock({
    required this.value,
    required this.label,
    this.unit,
    this.emphasised = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: emphasised ? AppColors.accent : AppColors.paper2,
        border: Border.all(
          color: emphasised ? AppColors.accent : AppColors.ink,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTheme.display(
              36,
              color: emphasised ? AppColors.accentTint : AppColors.accent,
            ),
          ),
          if (unit != null)
            Text(
              unit!,
              style: AppTheme.body(
                11,
                color: emphasised ? AppColors.accentTint : AppColors.muted,
              ),
            ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTheme.body(
              11.5,
              color: emphasised ? AppColors.accentTint : AppColors.muted,
              weight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<DailyPoint> points;

  const _TrendChart({required this.points});

  @override
  Widget build(BuildContext context) {
    // Days with no plan have no rate; plotting them as 0 would invent
    // failures that never happened, so they're simply absent from the line.
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final rate = points[i].rate;
      if (rate != null) spots.add(FlSpot(i.toDouble(), rate * 100));
    }

    if (spots.length < 2) {
      return Text(
        'Not enough finished days to draw a trend yet.',
        style: AppTheme.body(14, color: AppColors.muted),
      );
    }

    return SizedBox(
      height: 190,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.muted.withValues(alpha: 0.25),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 50,
                reservedSize: 34,
                getTitlesWidget: (v, _) => Text(
                  '${v.round()}%',
                  style: AppTheme.body(10, color: AppColors.muted),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (points.length / 3).floorToDouble().clamp(1, 30),
                reservedSize: 26,
                getTitlesWidget: (v, _) {
                  final i = v.round();
                  if (i < 0 || i >= points.length) return const SizedBox.shrink();
                  final d = points[i].dayKey.substring(8);
                  return Text(
                    d,
                    style: AppTheme.body(10, color: AppColors.muted),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.ink,
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        '${s.y.round()}%',
                        AppTheme.body(12, color: AppColors.paper),
                      ))
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: AppColors.accent,
              barWidth: 2.5,
              dotData: FlDotData(
                show: spots.length <= 15,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3,
                  color: AppColors.accent,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.accent.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayBars extends StatelessWidget {
  final Map<int, double> byWeekday;

  const _WeekdayBars({required this.byWeekday});

  static const _names = {
    1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun',
  };

  @override
  Widget build(BuildContext context) {
    if (byWeekday.isEmpty) {
      return Text(
        'No weekday pattern yet.',
        style: AppTheme.body(14, color: AppColors.muted),
      );
    }

    return Column(
      children: [
        for (var wd = 1; wd <= 7; wd++) _bar(wd, byWeekday[wd]),
      ],
    );
  }

  Widget _bar(int wd, double? rate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              _names[wd]!,
              style: AppTheme.body(12.5, color: AppColors.muted, weight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.paper2,
                borderRadius: BorderRadius.circular(3),
              ),
              child: rate == null
                  ? null
                  : FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: rate.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              rate == null ? '—' : '${(rate * 100).round()}%',
              textAlign: TextAlign.right,
              style: AppTheme.body(12, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
