import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase();

  /// The instance the app uses. Tests construct their own via [AppDatabase]
  /// plus [useExisting] instead of touching this one.
  static final AppDatabase instance = AppDatabase();

  static const _dbName = 'plan_tomorrow.db';
  static const _dbVersion = 3;

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
  /// if they'd already begun before opening the app. `habit_streak_days`
  /// is sparse -- a row's mere presence means that date was ticked, so
  /// ticking is an insert and unticking is a delete. Only dates that are
  /// not in the future are ever allowed a row; that rule is enforced in
  /// the repository, not the schema.
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
    if (oldVersion < 3) {
      // The v2 shape (month/year + a pre-filled row per day) is being
      // replaced entirely by the start-date shape above -- there's no
      // reasonable way to carry v2 data forward, since "day 3 of
      // September" doesn't map onto "day 3 of a streak that started on
      // some arbitrary date". This feature hadn't shipped to real users
      // yet, so a clean cut here is the right call rather than writing
      // migration code for data nobody has.
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
