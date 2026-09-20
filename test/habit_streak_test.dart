import 'package:flutter_test/flutter_test.dart';
import 'package:plan_tomorrow/core/day_key.dart';
import 'package:plan_tomorrow/data/db/app_database.dart';
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
    await AppDatabase.createSchema(db, 3);
    repo = HabitStreakRepository(db: AppDatabase()..useExisting(db));
  });

  tearDown(() async => db.close());

  group('creation', () {
    test('starting today is allowed', () async {
      final s = await repo.create(
        name: 'Reading',
        startDate: DayKey.today(),
        targetLength: 30,
        attempt: 1,
      );
      expect(s.startDate, DayKey.today());
      expect(s.doneDates, isEmpty);
    });

    test('backdating the start date is allowed', () async {
      final backdated = DayKey.addDays(DayKey.today(), -5);
      final s = await repo.create(
        name: 'Reading',
        startDate: backdated,
        targetLength: 30,
        attempt: 1,
      );
      expect(s.startDate, backdated);
    });

    test('starting in the future is rejected', () async {
      final tomorrow = DayKey.tomorrow();
      expect(
        () => repo.create(
            name: 'Reading', startDate: tomorrow, targetLength: 30, attempt: 1),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('the future-day lock', () {
    test('ticking tomorrow is rejected even if the streak started today',
        () async {
      final s = await repo.create(
        name: 'Test',
        startDate: DayKey.today(),
        targetLength: 30,
        attempt: 1,
      );
      expect(
        () => repo.toggleDay(s.id, DayKey.tomorrow()),
        throwsA(isA<StateError>()),
      );
    });

    test('ticking today and the past is allowed', () async {
      final start = DayKey.addDays(DayKey.today(), -2);
      final s = await repo.create(
          name: 'Test', startDate: start, targetLength: 30, attempt: 1);

      await repo.toggleDay(s.id, start); // day 1, two days ago
      await repo.toggleDay(s.id, DayKey.today()); // day 3, today

      final reloaded = await repo.getById(s.id);
      expect(reloaded!.doneDates.length, 2);
    });
  });

  group('backdating resolves the original conflict', () {
    test('a streak backdated 5 days already has those days elapsed, not locked',
        () async {
      final start = DayKey.addDays(DayKey.today(), -5);
      final s = await repo.create(
          name: 'Test', startDate: start, targetLength: 30, attempt: 1);

      // Every one of the 6 elapsed days (day 1..6, i.e. 5 days ago through
      // today) should be tickable -- none of them should throw, unlike the
      // old month-grid design where "days before today" were force-locked.
      for (var i = 0; i <= 5; i++) {
        final key = DayKey.addDays(start, i);
        await repo.toggleDay(s.id, key); // must not throw
      }

      final reloaded = await repo.getById(s.id);
      expect(reloaded!.doneDates.length, 6);
      expect(reloaded.currentStreakFromStart, 6);
    });
  });

  group('streak math', () {
    test('current streak counts consecutive ticks from day 1', () async {
      final start = DayKey.addDays(DayKey.today(), -4);
      final s = await repo.create(
          name: 'Test', startDate: start, targetLength: 30, attempt: 1);

      await repo.toggleDay(s.id, DayKey.addDays(start, 0)); // day 1
      await repo.toggleDay(s.id, DayKey.addDays(start, 1)); // day 2
      await repo.toggleDay(s.id, DayKey.addDays(start, 2)); // day 3

      final reloaded = await repo.getById(s.id);
      expect(reloaded!.currentStreakFromStart, 3);
    });

    test('a tick out of order does not extend the day-1 streak', () async {
      final start = DayKey.addDays(DayKey.today(), -4);
      final s = await repo.create(
          name: 'Test', startDate: start, targetLength: 30, attempt: 1);

      await repo.toggleDay(s.id, DayKey.addDays(start, 0)); // day 1
      await repo.toggleDay(
          s.id, DayKey.addDays(start, 3)); // day 4, skips ahead

      final reloaded = await repo.getById(s.id);
      expect(reloaded!.currentStreakFromStart, 1);
      expect(reloaded.totalDone, 2);
    });

    test(
        'an unticked day does not falsely extend past it, even with days ticked later',
        () async {
      final start = DayKey.addDays(DayKey.today(), -6);
      final s = await repo.create(
          name: 'Test', startDate: start, targetLength: 30, attempt: 1);

      await repo.toggleDay(s.id, DayKey.addDays(start, 0));
      await repo.toggleDay(s.id, DayKey.addDays(start, 1));
      // day index 2 (the 3rd day) deliberately left unticked
      await repo.toggleDay(s.id, DayKey.addDays(start, 3));
      await repo.toggleDay(s.id, DayKey.addDays(start, 4));

      final reloaded = await repo.getById(s.id);
      expect(reloaded!.currentStreakFromStart, 2);
    });

    test('untoggling removes a tick', () async {
      final start = DayKey.today();
      final s = await repo.create(
          name: 'Test', startDate: start, targetLength: 30, attempt: 1);

      await repo.toggleDay(s.id, start);
      var reloaded = await repo.getById(s.id);
      expect(reloaded!.doneDates.contains(start), isTrue);

      await repo.toggleDay(s.id, start); // untick
      reloaded = await repo.getById(s.id);
      expect(reloaded!.doneDates.contains(start), isFalse);
    });
  });

  group('elapsed days and milestones', () {
    test('elapsed days is clamped to target length', () async {
      final start = DayKey.addDays(DayKey.today(), -40);
      final s = await repo.create(
          name: 'Test', startDate: start, targetLength: 30, attempt: 1);
      expect(s.elapsedDays, 30);
    });

    test('elapsed days for a streak started today is 1', () async {
      final s = await repo.create(
          name: 'Test',
          startDate: DayKey.today(),
          targetLength: 30,
          attempt: 1);
      expect(s.elapsedDays, 1);
    });

    test('milestones adapt to a short target length', () async {
      final s = await repo.create(
          name: 'Test',
          startDate: DayKey.today(),
          targetLength: 14,
          attempt: 1);
      expect(s.milestoneDays, [7, 14]);
    });
  });

  group('attempt suggestion', () {
    test('suggests one past the highest existing attempt, case-insensitive',
        () async {
      await repo.create(
          name: 'Cold showers',
          startDate: DayKey.today(),
          targetLength: 30,
          attempt: 1);
      await repo.create(
          name: 'COLD SHOWERS',
          startDate: DayKey.today(),
          targetLength: 30,
          attempt: 2);
      expect(await repo.suggestNextAttempt('cold showers'), 3);
    });
  });

  group('deletion', () {
    test('deleting a streak removes its ticked days too', () async {
      final s = await repo.create(
          name: 'Test',
          startDate: DayKey.today(),
          targetLength: 30,
          attempt: 1);
      await repo.toggleDay(s.id, DayKey.today());
      await repo.delete(s.id);

      expect(await repo.getById(s.id), isNull);
      final dayRows = await db.query('habit_streak_days',
          where: 'streak_id = ?', whereArgs: [s.id]);
      expect(dayRows, isEmpty);
    });
  });
}
