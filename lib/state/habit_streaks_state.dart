import 'package:flutter/foundation.dart';

import '../data/models/habit_streak.dart';
import '../data/repositories/habit_streak_repository.dart';

class HabitStreaksState extends ChangeNotifier {
  final HabitStreakRepository repo;

  HabitStreaksState({HabitStreakRepository? repository})
      : repo = repository ?? HabitStreakRepository();

  bool _loading = true;
  List<HabitStreak> _streaks = [];

  bool get isLoading => _loading;
  List<HabitStreak> get streaks => _streaks;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    _streaks = await repo.getAll();

    _loading = false;
    notifyListeners();
  }

  Future<int> suggestNextAttempt(String name) => repo.suggestNextAttempt(name);

  Future<HabitStreak> create({
    required String name,
    required int month,
    required int year,
    required int attempt,
  }) async {
    final created = await repo.create(name: name, month: month, year: year, attempt: attempt);
    await load();
    return created;
  }

  Future<void> toggleDay(int streakId, int dayIndex) async {
    await repo.toggleDay(streakId, dayIndex);
    await load();
  }

  Future<void> delete(int streakId) async {
    await repo.delete(streakId);
    await load();
  }
}