import 'package:flutter_test/flutter_test.dart';
import 'package:plan_tomorrow/core/day_key.dart';
import 'package:plan_tomorrow/data/db/app_database.dart';
import 'package:plan_tomorrow/data/repositories/task_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// These run against a real in-memory sqlite database via the ffi backend,
/// so the repository's SQL is exercised rather than mocked away.
void main() {
  late Database db;
  late TaskRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await AppDatabase.createSchema(db, 1);
    repo = TaskRepository(db: AppDatabase()..useExisting(db));
  });

  tearDown(() async => db.close());

  Future<void> seed(String dayKey, int total, int done) async {
    for (var i = 0; i < total; i++) {
      await db.insert('tasks', {
        'day_key': dayKey,
        'title': 'Task $i',
        'is_done': i < done ? 1 : 0,
        'position': i,
      });
    }
  }

  group('streaks', () {
    test('empty database yields empty stats', () async {
      final stats = await repo.getStats();
      expect(stats.hasData, isFalse);
      expect(stats.currentStreak, 0);
    });

    test('perfect days in a row build a streak', () async {
      await seed(DayKey.addDays(DayKey.today(), -2), 3, 3);
      await seed(DayKey.addDays(DayKey.today(), -1), 2, 2);
      await seed(DayKey.today(), 4, 4);

      final stats = await repo.getStats();
      expect(stats.currentStreak, 3);
      expect(stats.bestStreak, 3);
    });

    test('an unfinished today does not reset the streak', () async {
      await seed(DayKey.addDays(DayKey.today(), -2), 3, 3);
      await seed(DayKey.addDays(DayKey.today(), -1), 2, 2);
      await seed(DayKey.today(), 4, 1); // still in progress

      final stats = await repo.getStats();
      expect(stats.currentStreak, 2);
    });

    test('a missed day breaks the streak', () async {
      await seed(DayKey.addDays(DayKey.today(), -3), 2, 2);
      await seed(DayKey.addDays(DayKey.today(), -2), 2, 1); // missed
      await seed(DayKey.addDays(DayKey.today(), -1), 2, 2);

      final stats = await repo.getStats();
      expect(stats.currentStreak, 1);
      expect(stats.bestStreak, 1);
    });

    test('a gap in dates is not contiguous', () async {
      await seed(DayKey.addDays(DayKey.today(), -10), 2, 2);
      await seed(DayKey.addDays(DayKey.today(), -1), 2, 2);

      final stats = await repo.getStats();
      expect(stats.bestStreak, 1);
    });
  });

  group('stats exclude the future', () {
    test('future plans do not count toward completion', () async {
      await seed(DayKey.addDays(DayKey.today(), -1), 2, 2);
      await seed(DayKey.tomorrow(), 5, 0); // planned, not yet happened

      final stats = await repo.getStats();
      expect(stats.tasksPlanned, 2);
      expect(stats.overallRate, 1.0);
    });
  });

  group('planning rules', () {
    test('planning is rejected for today and the past', () async {
      expect(
        () => repo.savePlan(DayKey.today(), ['a']),
        throwsA(isA<StateError>()),
      );
      expect(
        () => repo.savePlan(DayKey.yesterday(), ['a']),
        throwsA(isA<StateError>()),
      );
    });

    test('saving a plan replaces the previous one', () async {
      await repo.savePlan(DayKey.tomorrow(), ['one', 'two']);
      await repo.savePlan(DayKey.tomorrow(), ['three']);

      final plan = await repo.getTomorrow();
      expect(plan.tasks.length, 1);
      expect(plan.tasks.first.title, 'three');
    });

    test('blank entries are dropped and the cap is enforced', () async {
      await repo.savePlan(DayKey.tomorrow(), [
        'real',
        '   ',
        '',
        ...List.generate(20, (i) => 'extra $i'),
      ]);

      final plan = await repo.getTomorrow();
      expect(plan.tasks.length, TaskRepository.maxTasksPerDay);
      expect(plan.tasks.first.title, 'real');
    });

    test('ticking is rejected on days that are not today', () async {
      await repo.savePlan(DayKey.tomorrow(), ['later']);
      final plan = await repo.getTomorrow();

      expect(
        () => repo.toggleTask(plan.tasks.first.id!),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('ranges', () {
    test('continuous range fills gaps with empty days', () async {
      await seed(DayKey.addDays(DayKey.today(), -3), 2, 1);

      final pts = await repo.getContinuousRange(
        DayKey.addDays(DayKey.today(), -5),
        DayKey.today(),
      );

      expect(pts.length, 6);
      expect(pts.where((p) => p.hasPlan).length, 1);
    });
  });
}
