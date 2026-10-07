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
    await AppDatabase.createSchema(db, 5);
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

    test('a missed day is reported as the streak break', () async {
      await seed(DayKey.addDays(DayKey.today(), -3), 2, 2);
      await seed(DayKey.addDays(DayKey.today(), -1), 2, 0); // missed both, breaks the streak
      await seed(DayKey.today(), 1, 0); // today not finished yet either

      final stats = await repo.getStats();
      expect(stats.currentStreak, 0);
      expect(stats.streakBreakDay, DayKey.addDays(DayKey.today(), -1));
      expect(stats.streakBreakMissed, 2);
      expect(stats.hasRecentBreak, isTrue);
    });

    test('no break is reported when there is simply no history', () async {
      await seed(DayKey.today(), 3, 0); // nothing done yet today, no prior days

      final stats = await repo.getStats();
      expect(stats.currentStreak, 0);
      expect(stats.streakBreakDay, isNull);
      expect(stats.hasRecentBreak, isFalse);
    });

    test('milestone flag fires only at named streak lengths', () async {
      for (var i = 1; i <= 7; i++) {
        await seed(DayKey.addDays(DayKey.today(), -i), 1, 1);
      }
      final stats = await repo.getStats();
      expect(stats.currentStreak, 7);
      expect(stats.isAtMilestone, isTrue);
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
        () => repo.savePlan(DayKey.today(), [(title: 'a', scheduledTime: null)]),
        throwsA(isA<StateError>()),
      );
      expect(
        () => repo.savePlan(DayKey.yesterday(), [(title: 'a', scheduledTime: null)]),
        throwsA(isA<StateError>()),
      );
    });

    test('saving a plan replaces the previous one', () async {
      await repo.savePlan(DayKey.tomorrow(), [
        (title: 'one', scheduledTime: null),
        (title: 'two', scheduledTime: null),
      ]);
      await repo.savePlan(DayKey.tomorrow(), [
        (title: 'three', scheduledTime: null),
      ]);

      final plan = await repo.getTomorrow();
      expect(plan.tasks.length, 1);
      expect(plan.tasks.first.title, 'three');
    });

    test('blank entries are dropped and the cap is enforced', () async {
      await repo.savePlan(DayKey.tomorrow(), [
        (title: 'real', scheduledTime: null),
        (title: '   ', scheduledTime: null),
        (title: '', scheduledTime: null),
        ...List.generate(20, (i) => (title: 'extra $i', scheduledTime: null)),
      ]);

      final plan = await repo.getTomorrow();
      expect(plan.tasks.length, TaskRepository.maxTasksPerDay);
      expect(plan.tasks.first.title, 'real');
    });

    test('ticking is rejected on days that are not today', () async {
      await repo.savePlan(DayKey.tomorrow(), [(title: 'later', scheduledTime: null)]);
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