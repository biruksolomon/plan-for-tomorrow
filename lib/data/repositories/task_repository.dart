import 'package:sqflite/sqflite.dart';

import '../../core/day_key.dart';
import '../db/app_database.dart';
import '../models/day_plan.dart';
import '../models/stats.dart';
import '../models/task.dart';

class TaskRepository {
  final AppDatabase _db;

  TaskRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  // ---------------------------------------------------------------- reads

  Future<DayPlan> getDay(String dayKey) async {
    final db = await _db.database;
    final rows = await db.query(
      'tasks',
      where: 'day_key = ?',
      whereArgs: [dayKey],
      orderBy: 'position ASC',
    );
    return DayPlan(
      dayKey: dayKey,
      tasks: rows.map(Task.fromMap).toList(),
    );
  }

  Future<DayPlan> getToday() => getDay(DayKey.today());

  Future<DayPlan> getTomorrow() => getDay(DayKey.tomorrow());

  /// Inclusive on both ends.
  Future<List<DailyPoint>> getRange(String fromKey, String toKey) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT day_key,
             COUNT(*)                AS total,
             SUM(is_done)            AS done
      FROM tasks
      WHERE day_key >= ? AND day_key <= ?
      GROUP BY day_key
      ORDER BY day_key ASC
      ''',
      [fromKey, toKey],
    );

    return rows
        .map((r) => DailyPoint(
              dayKey: r['day_key'] as String,
              total: (r['total'] as int?) ?? 0,
              done: (r['done'] as int?) ?? 0,
            ))
        .toList();
  }

  /// Range with gaps filled in as empty days — charts and calendars need a
  /// continuous series, not just the days that happen to have rows.
  Future<List<DailyPoint>> getContinuousRange(
    String fromKey,
    String toKey,
  ) async {
    final present = {for (final p in await getRange(fromKey, toKey)) p.dayKey: p};
    final out = <DailyPoint>[];
    final span = DayKey.daysBetween(fromKey, toKey);
    for (var i = 0; i <= span; i++) {
      final key = DayKey.addDays(fromKey, i);
      out.add(present[key] ?? DailyPoint(dayKey: key, total: 0, done: 0));
    }
    return out;
  }

  // --------------------------------------------------------------- writes

  /// Replaces the plan for [dayKey].
  ///
  /// Only future days can be planned — this is the rule the whole app is
  /// built around, so it is enforced here at the data layer rather than
  /// trusted to the UI.
  Future<void> savePlan(String dayKey, List<String> titles) async {
    final plan = DayPlan.empty(dayKey);
    if (!plan.isEditable) {
      throw StateError(
        'Cannot edit $dayKey: planning is only allowed for future days.',
      );
    }

    final cleaned = titles
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .take(maxTasksPerDay)
        .toList();

    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('tasks', where: 'day_key = ?', whereArgs: [dayKey]);
      for (var i = 0; i < cleaned.length; i++) {
        await txn.insert('tasks', {
          'day_key': dayKey,
          'title': cleaned[i],
          'is_done': 0,
          'position': i,
        });
      }
    });
  }

  /// Flips one task. Only allowed on today — the past is frozen and the
  /// future hasn't started.
  Future<void> toggleTask(int taskId) async {
    final db = await _db.database;
    final rows = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final task = Task.fromMap(rows.first);
    final plan = DayPlan.empty(task.dayKey);
    if (!plan.isTickable) {
      throw StateError('Cannot tick ${task.dayKey}: only today can be ticked.');
    }

    await db.update(
      'tasks',
      {'is_done': task.isDone ? 0 : 1},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> deleteDay(String dayKey) async {
    final db = await _db.database;
    await db.delete('tasks', where: 'day_key = ?', whereArgs: [dayKey]);
  }

  Future<void> deleteAll() async {
    final db = await _db.database;
    await db.delete('tasks');
  }

  // ------------------------------------------------------------ analytics

  Future<Stats> getStats() async {
    final db = await _db.database;

    final rows = await db.rawQuery('''
      SELECT day_key,
             COUNT(*)     AS total,
             SUM(is_done) AS done
      FROM tasks
      GROUP BY day_key
      ORDER BY day_key ASC
    ''');

    if (rows.isEmpty) return Stats.empty();

    final points = rows
        .map((r) => DailyPoint(
              dayKey: r['day_key'] as String,
              total: (r['total'] as int?) ?? 0,
              done: (r['done'] as int?) ?? 0,
            ))
        .toList();

    final today = DayKey.today();

    // Future days are plans, not results — they must not count toward
    // completion stats or they'd show up as 0% failures before they happen.
    final past = points
        .where((p) => DayKey.daysBetween(p.dayKey, today) >= 0)
        .toList();

    if (past.isEmpty) return Stats.empty();

    var tasksPlanned = 0;
    var tasksDone = 0;
    var perfectDays = 0;
    for (final p in past) {
      tasksPlanned += p.total;
      tasksDone += p.done;
      if (p.isPerfect) perfectDays++;
    }

    final byDay = {for (final p in past) p.dayKey: p};

    return Stats(
      currentStreak: _currentStreak(byDay, today),
      bestStreak: _bestStreak(byDay, past),
      overallRate: tasksPlanned == 0 ? null : tasksDone / tasksPlanned,
      recentRate: _recentRate(byDay, today),
      daysPlanned: past.length,
      perfectDays: perfectDays,
      tasksPlanned: tasksPlanned,
      tasksDone: tasksDone,
      byWeekday: _byWeekday(past),
      recentDays: await getContinuousRange(DayKey.addDays(today, -29), today),
    );
  }

  /// Counts back from today. Today not yet finished doesn't break the streak:
  /// if today isn't perfect we start counting from yesterday instead, so the
  /// number doesn't drop to zero every morning.
  int _currentStreak(Map<String, DailyPoint> byDay, String today) {
    var cursor = today;
    if (!(byDay[today]?.isPerfect ?? false)) {
      cursor = DayKey.addDays(today, -1);
    }

    var streak = 0;
    while (true) {
      final point = byDay[cursor];
      if (point == null || !point.isPerfect) break;
      streak++;
      cursor = DayKey.addDays(cursor, -1);
    }
    return streak;
  }

  int _bestStreak(Map<String, DailyPoint> byDay, List<DailyPoint> past) {
    var best = 0;
    var run = 0;
    String? prevKey;

    for (final p in past) {
      final contiguous =
          prevKey != null && DayKey.daysBetween(prevKey, p.dayKey) == 1;
      if (p.isPerfect) {
        run = contiguous ? run + 1 : 1;
        if (run > best) best = run;
      } else {
        run = 0;
      }
      prevKey = p.dayKey;
    }
    return best;
  }

  double? _recentRate(Map<String, DailyPoint> byDay, String today) {
    var planned = 0;
    var done = 0;
    for (var i = 0; i < 30; i++) {
      final p = byDay[DayKey.addDays(today, -i)];
      if (p == null) continue;
      planned += p.total;
      done += p.done;
    }
    return planned == 0 ? null : done / planned;
  }

  Map<int, double> _byWeekday(List<DailyPoint> past) {
    final planned = <int, int>{};
    final done = <int, int>{};

    for (final p in past) {
      if (!p.hasPlan) continue;
      final wd = DayKey.weekday(p.dayKey);
      planned[wd] = (planned[wd] ?? 0) + p.total;
      done[wd] = (done[wd] ?? 0) + p.done;
    }

    final out = <int, double>{};
    planned.forEach((wd, total) {
      if (total > 0) out[wd] = (done[wd] ?? 0) / total;
    });
    return out;
  }

  // ------------------------------------------------------------- export

  /// Plain-text backup. No backend means this is the user's only way to
  /// move data off the device, so it stays human-readable on purpose.
  Future<String> exportCsv() async {
    final db = await _db.database;
    final rows = await db.query('tasks', orderBy: 'day_key ASC, position ASC');
    final buffer = StringBuffer('date,position,title,done\n');
    for (final r in rows) {
      final title = (r['title'] as String).replaceAll('"', '""');
      buffer.writeln(
        '${r['day_key']},${r['position']},"$title",${r['is_done']}',
      );
    }
    return buffer.toString();
  }

  static const int maxTasksPerDay = 10;
}
