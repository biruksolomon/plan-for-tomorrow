class UrgeActivity {
  final int dayNumber;
  final String title;
  final String category;
  final String description;
  final int durationSeconds;
  final List<String> steps;
  final String interactiveType; // 'breathing', 'timer', 'steps', 'cognitive'
  final String psychologicalBenefit;

  const UrgeActivity({
    required this.dayNumber,
    required this.title,
    required this.category,
    required this.description,
    required this.durationSeconds,
    required this.steps,
    required this.interactiveType,
    required this.psychologicalBenefit,
  });
}
