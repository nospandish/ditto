enum TaskImportance {
  optional('Optional'),
  canWait('Can wait'),
  mustComplete('Must complete');

  const TaskImportance(this.label);

  final String label;
}

class DittoTask {
  const DittoTask({
    required this.name,
    required this.minimumMinutes,
    required this.maximumMinutes,
    required this.importance,
    this.dueDate,
  });

  final String name;
  final DateTime? dueDate;
  final int minimumMinutes;
  final int maximumMinutes;
  final TaskImportance importance;
}
