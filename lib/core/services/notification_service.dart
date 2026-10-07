import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/task.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
      await androidImpl.requestExactAlarmsPermission();
    }
  }

  /// Schedules a notification for a specific task at its exact target time.
  Future<void> scheduleTaskAlarm({
    required int id,
    required String title,
    required DateTime scheduledTime,
  }) async {
    await init();
    if (scheduledTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'task_alarms',
      'Task Alarms',
      channelDescription: 'Alarms scheduled for specific task times',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _notifications.zonedSchedule(
      id,
      'Task Reminder',
      title,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedules progressive, sequential notifications for untimed tasks ("one by one").
  /// Spacing out uncompleted tasks across the day.
  Future<void> updateTaskSequenceQueue(List<Task> todayTasks) async {
    await init();
    final uncompleted = todayTasks.where((t) => !t.isDone).toList();
    if (uncompleted.isEmpty) return;

    final now = DateTime.now();

    // Schedule notifications for uncompleted tasks every 2 hours starting 1 hour from now
    for (var i = 0; i < uncompleted.length; i++) {
      final task = uncompleted[i];
      final targetTime = now.add(Duration(hours: 1 + i * 2));
      final notificationId = 1000 + (task.id ?? i);

      // If task has explicit scheduledTime, use that instead
      if (task.scheduledTime != null) {
        final parts = task.scheduledTime!.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]) ?? 9;
          final minute = int.tryParse(parts[1]) ?? 0;
          final exactDateTime = DateTime(now.year, now.month, now.day, hour, minute);
          if (exactDateTime.isAfter(now)) {
            await scheduleTaskAlarm(
              id: notificationId,
              title: task.title,
              scheduledTime: exactDateTime,
            );
            continue;
          }
        }
      }

      // Untimed sequential task nudge
      const androidDetails = AndroidNotificationDetails(
        'task_sequence',
        'Next Task Nudge',
        channelDescription: 'Sequential reminders for your next task',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      await _notifications.zonedSchedule(
        notificationId,
        i == 0 ? 'Next Task to Complete' : 'Upcoming Task',
        '#${task.position + 1}: ${task.title}',
        tz.TZDateTime.from(targetTime, tz.local),
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelTaskNotification(int id) async {
    await init();
    await _notifications.cancel(id);
    await _notifications.cancel(1000 + id);
  }

  Future<void> scheduleEveningPlanningReminder() async {
    await init();
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, 20, 0); // 8:00 PM
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'evening_planning',
      'Evening Planning Nudge',
      channelDescription: 'Reminder to plan tomorrow before midnight',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _notifications.zonedSchedule(
      9999,
      'Plan Tomorrow Tonight',
      "Set tomorrow's 10 tasks now so your morning starts with clarity.",
      tz.TZDateTime.from(scheduled, tz.local),
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
