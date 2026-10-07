class Task {
  final int? id;
  final String dayKey;
  final String title;
  final bool isDone;
  final int position;
  final String? scheduledTime; // HH:mm format, e.g. "08:30" or null for all-day

  const Task({
    this.id,
    required this.dayKey,
    required this.title,
    this.isDone = false,
    required this.position,
    this.scheduledTime,
  });

  Task copyWith({
    int? id,
    String? dayKey,
    String? title,
    bool? isDone,
    int? position,
    String? scheduledTime,
  }) {
    return Task(
      id: id ?? this.id,
      dayKey: dayKey ?? this.dayKey,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      position: position ?? this.position,
      scheduledTime: scheduledTime ?? this.scheduledTime,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'day_key': dayKey,
        'title': title,
        'is_done': isDone ? 1 : 0,
        'position': position,
        'scheduled_time': scheduledTime,
      };

  factory Task.fromMap(Map<String, Object?> map) => Task(
        id: map['id'] as int?,
        dayKey: map['day_key'] as String,
        title: map['title'] as String,
        isDone: (map['is_done'] as int) == 1,
        position: map['position'] as int,
        scheduledTime: map['scheduled_time'] as String?,
      );
}
