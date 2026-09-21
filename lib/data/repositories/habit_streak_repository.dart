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
      columns: ['day_key', 'status', 'reason'],
      where: 'streak_id = ?',
      whereArgs: [id],
    );

    final doneDates = <String>{};
    final missedReasons = <String, String>{};
    for (final r in dayRows) {
      final key = r['day_key'] as String;
      final status = r['status'] as String;
      if (status == 'done') {
        doneDates.add(key);
      } else if (status == 'missed') {
        missedReasons[key] = (r['reason'] as String?) ?? '';
      }
    }

    return HabitStreak(
      id: id,
      name: row['name'] as String,
      startDate: row['start_date'] as String,
      targetLength: row['target_length'] as int,
      attempt: row['attempt'] as int,
      createdAt: row['created_at'] as int,
      doneDates: doneDates,
      missedReasons: missedReasons,
    );
  }

  /// [startDate] must not be in the future -- there's no such thing as
  /// starting a streak tomorrow. This only anchors day-1 for counting; it
  /// does not restrict which days can later be marked.
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
      missedReasons: const {},
    );
  }

  void _assertNotFuture(String dayKey) {
    if (DayKey.daysBetween(DayKey.today(), dayKey) > 0) {
      throw StateError('Cannot log a day that has not happened yet.');
    }
  }

  /// Marks a day done, overwriting any prior missed status (and discarding
  /// its reason) on that same date -- a direct "set to done", not a raw
  /// toggle. Call [clearDay] to blank a day that's already done.
  Future<void> markDone(int streakId, String dayKey) async {
    _assertNotFuture(dayKey);
    final db = await _db.database;
    await db.insert(
      'habit_streak_days',
      {'streak_id': streakId, 'day_key': dayKey, 'status': 'done', 'reason': null},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Marks a day missed. [reason] is required and cannot be blank -- a
  /// missed day always has to say why, so the record is actually useful
  /// later. Overwrites any prior done status on that date.
  ///
  /// If this specific miss breaks the streak's currently-active run --
  /// i.e. every day from day 1 up to (but not including) this one was
  /// already done, so this was the very next day in the chain -- a new
  /// attempt is spawned automatically, starting the day after this one,
  /// with the attempt number incremented. Returns that new streak so the
  /// caller can navigate to it; returns null when nothing was spawned,
  /// which covers both an unbroken streak continuing normally and someone
  /// backfilling an old day that's already outside the live run (that's a
  /// historical correction, not a live failure -- it shouldn't spin up a
  /// new attempt on its own).
  Future<HabitStreak?> markMissed(int streakId, String dayKey, String reason) async {
    _assertNotFuture(dayKey);
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw ArgumentError('A reason is required to mark a day missed.');
    }

    final before = await getById(streakId);
    if (before == null) {
      throw StateError('No streak with id $streakId.');
    }

    final currentRun = before.currentStreakFromStart;
    final isFrontier = dayKey == before.dayKeyFor(currentRun + 1);
    // A streak that already hit its target shouldn't auto-spawn a new
    // attempt off a day logged after the fact -- that's success, not
    // failure, however the day gets marked later.
    final alreadyComplete = currentRun >= before.targetLength;

    final db = await _db.database;
    await db.insert(
      'habit_streak_days',
      {'streak_id': streakId, 'day_key': dayKey, 'status': 'missed', 'reason': cleanReason},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (!isFrontier || alreadyComplete) return null;

    final nextStart = DayKey.addDays(dayKey, 1);
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    final newId = await db.insert('habit_streaks', {
      'name': before.name,
      'start_date': nextStart,
      'target_length': before.targetLength,
      'attempt': before.attempt + 1,
      'created_at': createdAt,
    });

    return HabitStreak(
      id: newId,
      name: before.name,
      startDate: nextStart,
      targetLength: before.targetLength,
      attempt: before.attempt + 1,
      createdAt: createdAt,
      doneDates: const {},
      missedReasons: const {},
    );
  }

  /// Clears a day back to blank -- removing a done or missed status,
  /// reason included. No reason needed to clear; only to set missed.
  Future<void> clearDay(int streakId, String dayKey) async {
    final db = await _db.database;
    await db.delete(
      'habit_streak_days',
      where: 'streak_id = ? AND day_key = ?',
      whereArgs: [streakId, dayKey],
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