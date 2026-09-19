import 'package:sqflite/sqflite.dart';

import '../../core/day_key.dart';
import '../db/app_database.dart';
import '../models/habit_streak.dart';

class HabitStreakRepository {
  final AppDatabase _db;

  HabitStreakRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  /// Newest first -- matches how the list screen presents them.
  Future<List<HabitStreak>> getAll() async {
    final db = await _db.database;
    final streakRows = await db.query('habit_streaks', orderBy: 'created_at DESC');

    final result = <HabitStreak>[];
    for (final row in streakRows) {
      result.add(await _hydrate(db, row));
    }
    return result;
  }

  Future<HabitStreak?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query('habit_streaks', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return _hydrate(db, rows.first);
  }

  Future<HabitStreak> _hydrate(Database db, Map<String, Object?> row) async {
    final id = row['id'] as int;
    final dayRows = await db.query(
      'habit_streak_days',
      where: 'streak_id = ?',
      whereArgs: [id],
      orderBy: 'day_index ASC',
    );
    return HabitStreak(
      id: id,
      name: row['name'] as String,
      month: row['month'] as int,
      year: row['year'] as int,
      attempt: row['attempt'] as int,
      createdAt: row['created_at'] as int,
      days: dayRows.map((r) => (r['is_done'] as int) == 1).toList(),
    );
  }

  /// Creates a streak and pre-inserts one row per day of the chosen month,
  /// all unticked. Ticking is then always an UPDATE, never an INSERT --
  /// simpler and avoids a whole class of "day row doesn't exist yet" bugs.
  Future<HabitStreak> create({
    required String name,
    required int month,
    required int year,
    required int attempt,
  }) async {
    final db = await _db.database;
    final total = DayKey.daysInMonth(year, month);
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    final cleanName = name.trim();

    late int id;
    await db.transaction((txn) async {
      id = await txn.insert('habit_streaks', {
        'name': cleanName,
        'month': month,
        'year': year,
        'attempt': attempt,
        'created_at': createdAt,
      });
      for (var day = 1; day <= total; day++) {
        await txn.insert('habit_streak_days', {
          'streak_id': id,
          'day_index': day,
          'is_done': 0,
        });
      }
    });

    return HabitStreak(
      id: id,
      name: cleanName,
      month: month,
      year: year,
      attempt: attempt,
      createdAt: createdAt,
      days: List.filled(total, false),
    );
  }

  Future<void> toggleDay(int streakId, int dayIndex) async {
    final db = await _db.database;
    final rows = await db.query(
      'habit_streak_days',
      where: 'streak_id = ? AND day_index = ?',
      whereArgs: [streakId, dayIndex],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final isDone = (rows.first['is_done'] as int) == 1;
    await db.update(
      'habit_streak_days',
      {'is_done': isDone ? 0 : 1},
      where: 'streak_id = ? AND day_index = ?',
      whereArgs: [streakId, dayIndex],
    );
  }

  Future<void> delete(int streakId) async {
    final db = await _db.database;
    // Deleted explicitly rather than relying solely on the ON DELETE CASCADE
    // foreign key -- cascade behaviour varies across sqflite platform
    // backends, so this stays correct even where it's not enforced.
    await db.transaction((txn) async {
      await txn.delete('habit_streak_days', where: 'streak_id = ?', whereArgs: [streakId]);
      await txn.delete('habit_streaks', where: 'id = ?', whereArgs: [streakId]);
    });
  }

  /// One more than the highest attempt number already used for this name,
  /// case-insensitively -- so starting a new attempt at something you've
  /// tried before numbers itself automatically.
  Future<int> suggestNextAttempt(String name) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT MAX(attempt) AS best FROM habit_streaks WHERE LOWER(name) = ?',
      [name.trim().toLowerCase()],
    );
    final best = rows.first['best'] as int?;
    return (best ?? 0) + 1;
  }
}