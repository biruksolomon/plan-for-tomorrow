import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase();

  /// The instance the app uses. Tests construct their own via [AppDatabase]
  /// plus [useExisting] instead of touching this one.
  static final AppDatabase instance = AppDatabase();

  static const _dbName = 'plan_tomorrow.db';
  static const _dbVersion = 4;

  Database? _db;

  /// Points this instance at an already-open database (an in-memory one in
  /// tests) so the repository can be exercised against real SQL.
  void useExisting(Database db) => _db = db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: createSchema,
      onUpgrade: _onUpgrade,
    );
  }

  /// Public so tests can build the same schema in memory.
  static Future<void> createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        day_key  TEXT    NOT NULL,
        title    TEXT    NOT NULL,
        is_done  INTEGER NOT NULL DEFAULT 0,
        position INTEGER NOT NULL
      )
    ''');

    // Every read is "give me one day" or "give me a date range", so day_key
    // carries all the query weight.
    await db.execute('CREATE INDEX idx_tasks_day_key ON tasks (day_key)');

    await _createHabitStreakTables(db);
  }

  /// Named streaks pinned to a real start date (not a calendar month) --
  /// independent of the daily task list. A streak has a target length
  /// (e.g. 30 days) but no fixed end tied to a month boundary: day 1 is
  /// whatever date the person actually started on, which can be backdated
  /// if they'd already begun before opening the app.
  ///
  /// `start_date` anchors the day-1..N streak count and the "Started on"
  /// label -- it does NOT gate which days can be marked. Any day up to and
  /// including today can be logged regardless of the streak's own start
  /// date; only the future is locked.
  ///
  /// `habit_streak_days` is sparse -- a row's mere presence means that date
  /// has been logged, either 'done' or 'missed'. Absence means blank/
  /// undecided, which is the only status that's free to overwrite either
  /// way without confirmation. A 'missed' row always carries a non-empty
  /// `reason`; that's enforced in the repository, not the schema, so it
  /// stays enforced even if a caller forgets to check.
  static Future<void> _createHabitStreakTables(Database db) async {
    await db.execute('''
      CREATE TABLE habit_streaks (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT    NOT NULL,
        start_date    TEXT    NOT NULL,
        target_length INTEGER NOT NULL,
        attempt       INTEGER NOT NULL,
        created_at    INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE habit_streak_days (
        streak_id  INTEGER NOT NULL,
        day_key    TEXT    NOT NULL,
        status     TEXT    NOT NULL,
        reason     TEXT,
        PRIMARY KEY (streak_id, day_key),
        FOREIGN KEY (streak_id) REFERENCES habit_streaks (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_streak_days_streak_id ON habit_streak_days (streak_id)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createHabitStreakTables(db);
      return;
    }
    if (oldVersion < 4) {
      // Both the v2 (month/year) and v3 (binary tick, no status/reason)
      // shapes are being replaced. This feature hasn't shipped to real
      // users yet, so a clean cut is the right call rather than writing
      // migration code for data nobody has -- v3's plain "ticked" rows
      // have no reasonable mapping onto v4's done/missed+reason shape
      // anyway (a bare tick doesn't tell us which one it should become).
      await db.execute('DROP TABLE IF EXISTS habit_streak_days');
      await db.execute('DROP TABLE IF EXISTS habit_streaks');
      await _createHabitStreakTables(db);
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
