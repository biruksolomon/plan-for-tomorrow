import 'package:flutter_test/flutter_test.dart';
import 'package:plan_tomorrow/core/day_key.dart';
import 'package:plan_tomorrow/data/db/app_database.dart';
import 'package:plan_tomorrow/data/models/habit_streak.dart';
import 'package:plan_tomorrow/data/repositories/habit_streak_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late HabitStreakRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await AppDatabase.createSchema(db, 5);
    repo = HabitStreakRepository(db: AppDatabase()..useExisting(db));
  });

  tearDown(() async => db.close());

  group('HabitStreak active streak calculation', () {
    test('consecutive done days ending today yield correct active streak', () {
      final today = DayKey.today();
      final streak = HabitStreak(
        id: 1,
        name: 'Test',
        startDate: DayKey.addDays(today, -5),
        targetLength: 30,
        attempt: 1,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        doneDates: {
          DayKey.addDays(today, -2),
          DayKey.addDays(today, -1),
          today,
        },
        missedReasons: const {},
      );

      expect(streak.currentStreakFromStart, 3);
    });

    test('consecutive done days ending yesterday yield correct streak when today is blank', () {
      final today = DayKey.today();
      final streak = HabitStreak(
        id: 1,
        name: 'Test',
        startDate: DayKey.addDays(today, -5),
        targetLength: 30,
        attempt: 1,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        doneDates: {
          DayKey.addDays(today, -2),
          DayKey.addDays(today, -1),
        },
        missedReasons: const {},
      );

      expect(streak.currentStreakFromStart, 2);
    });

    test('a missed day breaks the active streak', () {
      final today = DayKey.today();
      final streak = HabitStreak(
        id: 1,
        name: 'Test',
        startDate: DayKey.addDays(today, -5),
        targetLength: 30,
        attempt: 1,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        doneDates: {
          DayKey.addDays(today, -3),
          DayKey.addDays(today, -2),
        },
        missedReasons: {
          DayKey.addDays(today, -1): 'Tired',
        },
      );

      expect(streak.currentStreakFromStart, 0);
    });
  });

  group('HabitStreakRepository missed day locking', () {
    test('cannot mark done, mark missed, or clear a day that is already missed', () async {
      final today = DayKey.today();
      final created = await repo.create(
        name: 'Exercise',
        startDate: DayKey.addDays(today, -2),
        targetLength: 30,
        attempt: 1,
      );

      final missedDay = DayKey.addDays(today, -1);
      await repo.markMissed(created.id, missedDay, 'Busy with work');

      // Attempting to overwrite with markDone must fail
      expect(
        () => repo.markDone(created.id, missedDay),
        throwsA(isA<StateError>()),
      );

      // Attempting to overwrite with markMissed must fail
      expect(
        () => repo.markMissed(created.id, missedDay, 'New reason'),
        throwsA(isA<StateError>()),
      );

      // Attempting to clear must fail
      expect(
        () => repo.clearDay(created.id, missedDay),
        throwsA(isA<StateError>()),
      );

      // Verify the missed status and reason remain intact
      final reloaded = await repo.getById(created.id);
      expect(reloaded!.isMissedOn(missedDay), isTrue);
      expect(reloaded.missedReasonOn(missedDay), 'Busy with work');
    });
  });
}
