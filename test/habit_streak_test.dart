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
    await AppDatabase.createSchema(db, 4);
    repo = HabitStreakRepository(db: AppDatabase()..useExisting(db));
  });

  tearDown(() async => db.close());

  group('creation', () {
    test('starting today is allowed', () async {
      final s = await repo.create(
          name: 'Reading',
          startDate: DayKey.today(),
          targetLength: 30,
          attempt: 1);
      expect(s.startDate, DayKey.today());
      expect(s.doneDates, isEmpty);
      expect(s.missedReasons, isEmpty);
    });

    test('backdating the start date is allowed', () async {
      final backdated = DayKey.addDays(DayKey.today(), -5);
      final s = await repo.create(
          name: 'Reading', startDate: backdated, targetLength: 30, attempt: 1);
      expect(s.startDate, backdated);
    });

    test('starting in the future is rejected', () async {
      expect(
        () => repo.create(
            name: 'Reading',
            startDate: DayKey.tomorrow(),
            targetLength: 30,
            attempt: 1),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('the only lock is the future', () {
    test('marking tomorrow done is rejected even if the streak started today',
        () async {
      final s = await repo.create(
          name: 'Test',
          startDate: DayKey.today(),
          targetLength: 30,
          attempt: 1);
      expect(() => repo.markDone(s.id, DayKey.tomorrow()),
          throwsA(isA<StateError>()));
    });

    test('marking tomorrow missed is also rejected', () async {
      final s = await repo.create(
          name: 'Test',
          startDate: DayKey.today(),
          targetLength: 30,
          attempt: 1);
      expect(() => repo.markMissed(s.id, DayKey.tomorrow(), 'no reason'),
          throwsA(isA<StateError>()));
    });

    test(
        'a day before the streak\'s own start date is still markable -- '
        'the start date only anchors the count, it does not lock anything',
        () async {
      // Streak "starts" today, but a day from well before that is still
      // open to log. This is the direct fix for the original bug report:
      // only today was tappable because start-date locking blocked
      // everything before it.
      final s = await repo.create(
          name: 'Test',
          startDate: DayKey.today(),
          targetLength: 30,
          attempt: 1);
      final longAgo = DayKey.addDays(DayKey.today(), -10);

      await repo.markDone(s.id, longAgo); // must not throw

      final reloaded = await repo.getById(s.id);
      expect(reloaded!.doneDates.contains(longAgo), isTrue);
    });
  });

  group('tri-state: done / missed / blank', () {
    test('markDone sets a day done', () async {
      final s = await repo.create(
          name: 'Test',
          startDate: DayKey.today(),
          targetLength: 30,
          attempt: 1);
      await repo.markDone(s.id, DayKey.today());

      final reloaded = await repo.getById(s.id);
      expect(reloaded!.isDoneOn(DayKey.today()), isTrue);
      expect(reloaded.isMissedOn(DayKey.today()), isFalse);
    });

    test('markMissed requires a non-empty reason', () async {
      final s = await repo.create(
          name: 'Test',
          startDate: DayKey.today(),
          targetLength: 30,
          attempt: 1);
      expect(() => repo.markMissed(s.id, DayKey.today(), ''),
          throwsA(isA<ArgumentError>()));
      expect(() => repo.markMissed(s.id, DayKey.today(), '   '),
          throwsA(isA<ArgumentError>()));
    });

    test('markMissed with a real reason stores it and is retrievable',
        () async {
      final s = await repo.create(
          name: 'Test',
          startDate: DayKey.today(),
          targetLength: 30,
          attempt: 1);
      await repo.markMissed(s.id, DayKey.today(), 'Was sick');

      final reloaded = await repo.getById(s.id);
      expect(reloaded!.isMissedOn(DayKey.today()), isTrue);
      expect(reloaded.missedReasonOn(DayKey.today()), 'Was sick');
    });

    test('markDone on a missed day overwrites it and drops the reason',
        () async {
      final s = await repo.create(
          name: 'Test',
          startDate: DayKey.today(),
          targetLength: 30,
          attempt: 1);
      await repo.markMissed(s.id, DayKey.today(), 'Was sick');
      await repo.markDone(s.id, DayKey.today());

      final reloaded = await repo.getById(s.id);
      expect(reloaded!.isDoneOn(DayKey.today()), isTrue);
      expect(reloaded.isMissedOn(DayKey.today()), isFalse);
    });

    test('clearDay returns a day to blank from either state', () async {
      final s = await repo.create(
          name: 'Test',
          startDate: DayKey.today(),
          targetLength: 30,
          attempt: 1);
      await repo.markDone(s.id, DayKey.today());
      await repo.clearDay(s.id, DayKey.today());

      final reloaded = await repo.getById(s.id);
      expect(reloaded!.isBlankOn(DayKey.today()), isTrue);
    });

    test('clearDay needs no reason to remove a missed day', () async {
      final s = await repo.create(
          name: 'Test',
          startDate: DayKey.today(),
          targetLength: 30,
          attempt: 1);
      await repo.markMissed(s.id, DayKey.today(), 'Was sick');
      await repo.clearDay(
          s.id, DayKey.today()); // must not throw, no reason passed

      final reloaded = await repo.getById(s.id);
      expect(reloaded!.isBlankOn(DayKey.today()), isTrue);
    });
  });

  group('streak math', () {
    test('current streak counts consecutive done days from day 1', () async {
      final start = DayKey.addDays(DayKey.today(), -4);
      final s = await repo.create(
          name: 'Test', startDate: start, targetLength: 30, attempt: 1);

      await repo.markDone(s.id, DayKey.addDays(start, 0));
      await repo.markDone(s.id, DayKey.addDays(start, 1));
      await repo.markDone(s.id, DayKey.addDays(start, 2));

      final reloaded = await repo.getById(s.id);
      expect(reloaded!.currentStreakFromStart, 3);
    });

    test('a missed day breaks the streak exactly like a blank one', () async {
      final start = DayKey.addDays(DayKey.today(), -4);
      final s = await repo.create(
          name: 'Test', startDate: start, targetLength: 30, attempt: 1);

      await repo.markDone(s.id, DayKey.addDays(start, 0));
      await repo.markMissed(s.id, DayKey.addDays(start, 1), 'Overslept');
      await repo.markDone(s.id, DayKey.addDays(start, 2));

      final reloaded = await repo.getById(s.id);
      expect(reloaded!.currentStreakFromStart, 1);
      expect(reloaded.totalDone, 2);
      expect(reloaded.totalMissed, 1);
    });
  });

  group('auto-advance to a new attempt on break', () {
    test('marking the live frontier day missed spawns attempt N+1', () async {
      final start = DayKey.addDays(DayKey.today(), -2);
      final s = await repo.create(
          name: 'Reading', startDate: start, targetLength: 30, attempt: 1);

      await repo.markDone(s.id, DayKey.addDays(start, 0)); // day 1
      await repo.markDone(s.id, DayKey.addDays(start, 1)); // day 2
      // Day 3 (today) is the very next day in the chain -- marking it
      // missed breaks the live run.
      final spawned = await repo.markMissed(s.id, DayKey.today(), 'Forgot');

      expect(spawned, isNotNull);
      expect(spawned!.attempt, 2);
      expect(spawned.startDate, DayKey.tomorrow());
      expect(spawned.name, 'Reading');

      final all = await repo.getAll();
      expect(all.length, 2); // original attempt is kept, not replaced
    });

    test(
        'backfilling an old day that is not the frontier does not spawn anything',
        () async {
      final start = DayKey.addDays(DayKey.today(), -10);
      final s = await repo.create(
          name: 'Reading', startDate: start, targetLength: 30, attempt: 1);

      // The chain already broke on day 1 (nothing was ever ticked), so
      // day 1's own start date is the frontier, not this later day.
      final laterDay = DayKey.addDays(start, 5);
      final spawned =
          await repo.markMissed(s.id, laterDay, 'Backfilling history');

      expect(spawned, isNull);
      expect(await repo.getAll(), hasLength(1));
    });

    test('a streak that already hit its target does not auto-spawn', () async {
      final start = DayKey.addDays(DayKey.today(), -1);
      final s = await repo.create(
          name: 'Short', startDate: start, targetLength: 2, attempt: 1);

      await repo.markDone(s.id, DayKey.addDays(start, 0)); // day 1
      await repo.markDone(
          s.id, DayKey.addDays(start, 1)); // day 2 (today) -- target hit

      // Nothing left in range to mark missed at the frontier since the
      // target's already complete; confirm no spawn if a day is revisited.
      final spawned =
          await repo.markMissed(s.id, DayKey.today(), 'Changed my mind');
      expect(spawned, isNull);
      expect(await repo.getAll(), hasLength(1));
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
    test('deleting a streak removes its logged days too', () async {
      final s = await repo.create(
          name: 'Test',
          startDate: DayKey.today(),
          targetLength: 30,
          attempt: 1);
      await repo.markDone(s.id, DayKey.today());
      await repo.delete(s.id);

      expect(await repo.getById(s.id), isNull);
      final dayRows = await db.query('habit_streak_days',
          where: 'streak_id = ?', whereArgs: [s.id]);
      expect(dayRows, isEmpty);
    });
  });
}
