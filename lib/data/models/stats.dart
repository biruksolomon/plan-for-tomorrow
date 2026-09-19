/// One day's completion, used for charts and heatmaps.
class DailyPoint {
  final String dayKey;
  final int total;
  final int done;

  const DailyPoint({
    required this.dayKey,
    required this.total,
    required this.done,
  });

  double? get rate => total == 0 ? null : done / total;
  bool get isPerfect => total > 0 && done == total;
  bool get hasPlan => total > 0;
}

class Stats {
  /// Consecutive perfect days ending today or yesterday.
  final int currentStreak;
  final int bestStreak;

  /// Tasks done / tasks planned, across every day that had a plan.
  final double? overallRate;

  /// Same, restricted to the last 30 days.
  final double? recentRate;

  final int daysPlanned;
  final int perfectDays;
  final int tasksPlanned;
  final int tasksDone;

  /// Completion rate per weekday, 1 = Monday ... 7 = Sunday.
  /// Missing key = no data for that weekday yet.
  final Map<int, double> byWeekday;

  /// Chronological, oldest first — drives the trend chart.
  final List<DailyPoint> recentDays;

  const Stats({
    required this.currentStreak,
    required this.bestStreak,
    required this.overallRate,
    required this.recentRate,
    required this.daysPlanned,
    required this.perfectDays,
    required this.tasksPlanned,
    required this.tasksDone,
    required this.byWeekday,
    required this.recentDays,
  });

  factory Stats.empty() => const Stats(
        currentStreak: 0,
        bestStreak: 0,
        overallRate: null,
        recentRate: null,
        daysPlanned: 0,
        perfectDays: 0,
        tasksPlanned: 0,
        tasksDone: 0,
        byWeekday: {},
        recentDays: [],
      );

  bool get hasData => daysPlanned > 0;

  /// Best and worst weekday by completion rate, or null when there isn't
  /// enough spread to say anything meaningful.
  int? get bestWeekday {
    if (byWeekday.length < 2) return null;
    final sorted = byWeekday.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  int? get worstWeekday {
    if (byWeekday.length < 2) return null;
    final sorted = byWeekday.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return sorted.first.key;
  }
}
