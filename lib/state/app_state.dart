import 'package:flutter/widgets.dart';

import '../core/day_key.dart';
import '../data/models/day_plan.dart';
import '../data/models/stats.dart';
import '../data/repositories/task_repository.dart';

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  final TaskRepository repo;

  AppState({TaskRepository? repository})
      : repo = repository ?? TaskRepository() {
    WidgetsBinding.instance.addObserver(this);
  }

  bool _loading = true;
  DayPlan _today = DayPlan.empty(DayKey.today());
  DayPlan _tomorrow = DayPlan.empty(DayKey.tomorrow());
  Stats _stats = Stats.empty();
  String _boundDate = DayKey.today();

  bool get isLoading => _loading;
  DayPlan get today => _today;
  DayPlan get tomorrow => _tomorrow;
  Stats get stats => _stats;

  /// True when tomorrow has no plan yet — drives the nudge on the Today screen.
  bool get needsTomorrowPlan => !_tomorrow.hasPlan;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    _boundDate = DayKey.today();
    _today = await repo.getToday();
    _tomorrow = await repo.getTomorrow();
    _stats = await repo.getStats();

    _loading = false;
    notifyListeners();
  }

  /// The app can sit in memory across midnight. When it comes back to the
  /// foreground we check whether the calendar date moved and, if so, reload
  /// so yesterday's list stops being presented as today's.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _boundDate != DayKey.today()) {
      load();
    }
  }

  Future<void> toggle(int taskId) async {
    await repo.toggleTask(taskId);
    _today = await repo.getToday();
    notifyListeners();

    // Stats are a heavier query; refresh them after the tick has already
    // been painted so the checkbox never feels laggy.
    _stats = await repo.getStats();
    notifyListeners();
  }

  Future<void> saveTomorrow(List<String> titles) async {
    await repo.savePlan(DayKey.tomorrow(), titles);
    _tomorrow = await repo.getTomorrow();
    _stats = await repo.getStats();
    notifyListeners();
  }

  Future<DayPlan> dayDetail(String dayKey) => repo.getDay(dayKey);

  Future<List<DailyPoint>> monthPoints(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    return repo.getContinuousRange(DayKey.of(first), DayKey.of(last));
  }

  Future<String> exportCsv() => repo.exportCsv();

  Future<void> resetEverything() async {
    await repo.deleteAll();
    await load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
