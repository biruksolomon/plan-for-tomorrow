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
    final streakRows =
        await db.query('habit_streaks', orderBy: 'created_at DESC');

    final result = <HabitStreak>[];
    for (final row in streakRows) {
      result.add(await _hydrate(db, row));
    }
    return result;
  }

  Future<HabitStreak?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query('habit_streaks',
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return _hydrate(db, rows.first);
  }

  Future<HabitStreak> _hydrate(Database db, Map<String, Object?> row) async {
    final id = row['id'] as int;
    final dayRows = await db.query(
      'habit_streak_days',
      columns: ['day_key'],
      where: 'streak_id = ?',
      whereArgs: [id],
    );
    return HabitStreak(
      id: id,
      name: row['name'] as String,
      startDate: row['start_date'] as String,
      targetLength: row['target_length'] as int,
      attempt: row['attempt'] as int,
      createdAt: row['created_at'] as int,
      doneDates: {for (final r in dayRows) r['day_key'] as String},
    );
  }

  /// [startDate] must not be in the future -- there's no such thing as
  /// starting a streak tomorrow. This is enforced here, not just left to
  /// the date picker's bounds, so the rule holds regardless of caller.
  Future<HabitStreak> create({
    required String name,
    required String startDate,
    required int targetLength,
    required int attempt,
  }) async {
    if (DayKey.daysBetween(DayKey.today(), startDate) > 0) {
      throw StateError('Cannot start a streak in the future.');
    }

    final db = await _db.database;
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    final cleanName = name.trim();

    final id = await db.insert('habit_streaks', {
      'name': cleanName,
      'start_date': startDate,
      'target_length': targetLength,
      'attempt': attempt,
      'created_at': createdAt,
    });

    return HabitStreak(
      id: id,
      name: cleanName,
      startDate: startDate,
      targetLength: targetLength,
      attempt: attempt,
      createdAt: createdAt,
      doneDates: const {},
    );
  }

  /// Toggles one date for one streak. Refuses future dates -- this is the
  /// actual enforcement point for "you can't tick ahead"; the UI disabling
  /// the tap is only a convenience on top of this.
  Future<void> toggleDay(int streakId, String dayKey) async {
    if (DayKey.daysBetween(DayKey.today(), dayKey) > 0) {
      throw StateError('Cannot tick a day that has not happened yet.');
    }

    final db = await _db.database;
    final existing = await db.query(
      'habit_streak_days',
      where: 'streak_id = ? AND day_key = ?',
      whereArgs: [streakId, dayKey],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert(
          'habit_streak_days', {'streak_id': streakId, 'day_key': dayKey});
    } else {
      await db.delete(
        'habit_streak_days',
        where: 'streak_id = ? AND day_key = ?',
        whereArgs: [streakId, dayKey],
      );
    }
  }

  Future<void> delete(int streakId) async {
    final db = await _db.database;
    // Deleted explicitly rather than relying solely on the ON DELETE CASCADE
    // foreign key -- cascade behaviour varies across sqflite platform
    // backends, so this stays correct even where it's not enforced.
    await db.transaction((txn) async {
      await txn.delete('habit_streak_days',
          where: 'streak_id = ?', whereArgs: [streakId]);
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
