import '../../core/day_key.dart';
import 'task.dart';

/// What the user is allowed to do with a day, derived purely from its date.
///
/// Nothing is stored for this: a day in the future is editable, today is
/// tick-only, the past is frozen. Deriving it means the app can never get
/// stuck in a stale state because a rollover job didn't run.
enum DayPhase {
  /// Date is in the future — the plan is still being written.
  planning,

  /// Date is today — locked for editing, open for ticking.
  active,

  /// Date has passed — read-only.
  archived,
}

class DayPlan {
  final String dayKey;
  final List<Task> tasks;

  const DayPlan({required this.dayKey, required this.tasks});

  factory DayPlan.empty(String dayKey) => DayPlan(dayKey: dayKey, tasks: const []);

  DayPhase get phase {
    final diff = DayKey.daysBetween(DayKey.today(), dayKey);
    if (diff > 0) return DayPhase.planning;
    if (diff == 0) return DayPhase.active;
    return DayPhase.archived;
  }

  bool get isEditable => phase == DayPhase.planning;
  bool get isTickable => phase == DayPhase.active;

  int get total => tasks.length;
  int get doneCount => tasks.where((t) => t.isDone).length;

  /// 0.0–1.0. A day with no tasks has no rate — callers treat it as "no data"
  /// rather than as a zero, so an untouched day doesn't drag averages down.
  double? get completionRate => total == 0 ? null : doneCount / total;

  /// A day "counts" for streak purposes only if something was planned and
  /// everything planned got done. Partial credit would make streaks meaningless.
  bool get isPerfect => total > 0 && doneCount == total;

  bool get hasPlan => total > 0;
}
