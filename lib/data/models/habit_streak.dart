/// A named streak tied to one real calendar month (e.g. "Morning workout,
/// September 2026, attempt 2"). Independent of the daily Plan Tomorrow /
/// Today task list -- this is for tracking a single habit day-by-day across
/// a whole month, the way the printed streak poster works.
class HabitStreak {
  static const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  final int id;
  final String name;
  final int month; // 1-12
  final int year;
  final int attempt;
  final int createdAt; // epoch millis, used only for sorting the list

  /// One entry per day of the month, index 0 = day 1.
  final List<bool> days;

  const HabitStreak({
    required this.id,
    required this.name,
    required this.month,
    required this.year,
    required this.attempt,
    required this.createdAt,
    required this.days,
  });

  String get monthLabel => '${monthNames[month - 1]} $year';

  /// Consecutive ticked days counting from day 1 -- the "don't break the
  /// chain" definition. A day ticked out of order (e.g. day 9 before day 6)
  /// doesn't extend this; it only counts once every day before it is also
  /// ticked. That mirrors the printed poster, which is filled in in order.
  int get currentStreakFromDay1 {
    var n = 0;
    for (final done in days) {
      if (done) {
        n++;
      } else {
        break;
      }
    }
    return n;
  }

  /// Every ticked day, regardless of order -- so ticking out of sequence
  /// still counts for something even though it doesn't extend the streak.
  int get totalDone => days.where((d) => d).length;

  /// Days worth calling out visually: weekly checkpoints plus the final day
  /// of the month, whatever length that turns out to be.
  List<int> get milestoneDays {
    final total = days.length;
    final out = [for (final m in const [7, 14, 21]) if (m < total) m];
    out.add(total);
    return out;
  }
}