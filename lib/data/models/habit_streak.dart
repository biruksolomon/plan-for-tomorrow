import '../../core/day_key.dart';

/// A named streak pinned to a real **start date** -- not a calendar month.
///
/// Day 1 is whatever date the person actually began on. This matters for
/// two things a month-based grid gets wrong: a streak that runs past a
/// month boundary doesn't reset just because the calendar page turned, and
/// someone who'd already started before opening the app can backdate the
/// start date instead of being forced onto "the 1st of this month".
class HabitStreak {
  final int id;
  final String name;

  /// "yyyy-MM-dd" -- day 1 of the streak.
  final String startDate;

  /// How many days this streak is aiming for (e.g. 30). Caps the grid; it
  /// does not cap how long ago [startDate] can be.
  final int targetLength;

  final int attempt;
  final int createdAt; // epoch millis, used only for sorting the list

  /// Every date that's been ticked, as "yyyy-MM-dd" keys. Sparse: an absent
  /// date just means "not ticked", not "doesn't exist yet".
  final Set<String> doneDates;

  const HabitStreak({
    required this.id,
    required this.name,
    required this.startDate,
    required this.targetLength,
    required this.attempt,
    required this.createdAt,
    required this.doneDates,
  });

  /// The date for day N of this streak (1-indexed).
  String dayKeyFor(int dayNumber) => DayKey.addDays(startDate, dayNumber - 1);

  /// A day beyond today can't be ticked -- there's nothing to report yet.
  bool isFuture(String dayKey) => DayKey.daysBetween(DayKey.today(), dayKey) > 0;

  bool isDoneOn(String dayKey) => doneDates.contains(dayKey);

  /// Consecutive ticked days counting from day 1 -- "don't break the
  /// chain". Stops at the first unticked day, or at today, whichever comes
  /// first; a day that hasn't happened yet can't extend or break it.
  int get currentStreakFromStart {
    var n = 0;
    for (var day = 1; day <= targetLength; day++) {
      final key = dayKeyFor(day);
      if (isFuture(key)) break;
      if (!doneDates.contains(key)) break;
      n++;
    }
    return n;
  }

  /// Every ticked day within the target range, regardless of order.
  int get totalDone {
    var n = 0;
    for (var day = 1; day <= targetLength; day++) {
      if (doneDates.contains(dayKeyFor(day))) n++;
    }
    return n;
  }

  /// How many days of the target have actually happened yet (today
  /// inclusive), clamped to the target length. Day 0 if the streak somehow
  /// starts in the future (shouldn't happen -- creation disallows it).
  int get elapsedDays {
    final diff = DayKey.daysBetween(startDate, DayKey.today()) + 1;
    if (diff < 0) return 0;
    return diff > targetLength ? targetLength : diff;
  }

  bool get isComplete =>
      elapsedDays >= targetLength && currentStreakFromStart >= targetLength;

  /// Days worth calling out visually: weekly checkpoints plus the final
  /// target day.
  List<int> get milestoneDays {
    final out = [for (final m in const [7, 14, 21]) if (m < targetLength) m];
    out.add(targetLength);
    return out;
  }
}