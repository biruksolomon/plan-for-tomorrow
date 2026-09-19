import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase();

  /// The instance the app uses. Tests construct their own via [AppDatabase]
  /// plus [useExisting] instead of touching this one.
  static final AppDatabase instance = AppDatabase();

  static const _dbName = 'plan_tomorrow.db';
  static const _dbVersion = 2;

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

  /// Named, calendar-bound streaks (e.g. "Morning workout, September 2026,
  /// attempt 2") -- independent of the daily task list. One row per day of
  /// the chosen month is inserted up front at creation time, so ticking is
  /// always an update, never an insert.
  static Future<void> _createHabitStreakTables(Database db) async {
    await db.execute('''
      CREATE TABLE habit_streaks (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL,
        month      INTEGER NOT NULL,
        year       INTEGER NOT NULL,
        attempt    INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE habit_streak_days (
        streak_id  INTEGER NOT NULL,
        day_index  INTEGER NOT NULL,
        is_done    INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (streak_id, day_index),
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
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}