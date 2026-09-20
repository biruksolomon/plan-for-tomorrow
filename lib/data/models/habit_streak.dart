import '../../core/day_key.dart';

/// A named streak pinned to a real **start date** -- not a calendar month.
///
/// Day 1 is whatever date the person actually began on. `startDate` anchors
/// the day-1..N streak count and the "Started on" label; it does NOT gate
/// which days can be logged. Any day up to and including today is open to
/// mark, regardless of how it compares to the streak's own start date --
/// only the future is off limits, since there's nothing to report on a day
/// that hasn't happened.
class HabitStreak {
  final int id;
  final String name;

  /// "yyyy-MM-dd" -- day 1 of the streak, for counting purposes only.
  final String startDate;

  /// How many days this streak is aiming for (e.g. 30). Caps the grid; it
  /// does not cap how long ago [startDate] can be.
  final int targetLength;

  final int attempt;
  final int createdAt; // epoch millis, used only for sorting the list

  /// Dates marked done, as "yyyy-MM-dd" keys.
  final Set<String> doneDates;

  /// Dates marked missed, mapped to the reason given for each -- a missed
  /// day always has one; that's enforced at the point it's recorded, not
  /// here.
  final Map<String, String> missedReasons;

  const HabitStreak({
    required this.id,
    required this.name,
    required this.startDate,
    required this.targetLength,
    required this.attempt,
    required this.createdAt,
    required this.doneDates,
    required this.missedReasons,
  });

  /// The date for day N of this streak (1-indexed).
  String dayKeyFor(int dayNumber) => DayKey.addDays(startDate, dayNumber - 1);

  /// A day beyond today can't be logged -- there's nothing to report yet.
  /// This is the *only* lock on interactivity; a day being before the
  /// streak's own start date does not block it.
  bool isFuture(String dayKey) =>
      DayKey.daysBetween(DayKey.today(), dayKey) > 0;

  bool isDoneOn(String dayKey) => doneDates.contains(dayKey);
  bool isMissedOn(String dayKey) => missedReasons.containsKey(dayKey);
  String? missedReasonOn(String dayKey) => missedReasons[dayKey];

  /// Blank means logged as neither done nor missed -- not the same as
  /// locked. A blank day within range is simply undecided so far.
  bool isBlankOn(String dayKey) => !isDoneOn(dayKey) && !isMissedOn(dayKey);

  /// Consecutive **done** days counting from day 1 -- "don't break the
  /// chain". A missed day breaks it exactly like a blank one does; marking
  /// the reason doesn't rescue the streak, it just records why it broke.
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

  /// Every done day within the target range, regardless of order.
  int get totalDone {
    var n = 0;
    for (var day = 1; day <= targetLength; day++) {
      if (doneDates.contains(dayKeyFor(day))) n++;
    }
    return n;
  }

  /// Every missed day within the target range -- shown alongside totalDone
  /// so a blank day (never addressed) reads differently from one that was
  /// actively marked missed.
  int get totalMissed {
    var n = 0;
    for (var day = 1; day <= targetLength; day++) {
      if (missedReasons.containsKey(dayKeyFor(day))) n++;
    }
    return n;
  }

  /// How many days of the target have actually happened yet (today
  /// inclusive), clamped to the target length.
  int get elapsedDays {
    final diff = DayKey.daysBetween(startDate, DayKey.today()) + 1;
    if (diff < 0) return 0;
    return diff > targetLength ? targetLength : diff;
  }

  /// Days worth calling out visually: weekly checkpoints plus the final
  /// target day.
  List<int> get milestoneDays {
    final out = [
      for (final m in const [7, 14, 21])
        if (m < targetLength) m
    ];
    out.add(targetLength);
    return out;
  }
}
