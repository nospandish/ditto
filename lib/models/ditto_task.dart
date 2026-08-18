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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dueDate': dueDate?.toIso8601String(),
      'minimumMinutes': minimumMinutes,
      'maximumMinutes': maximumMinutes,
      'importance': importance.name,
    };
  }

  factory DittoTask.fromJson(Map<String, dynamic> json) {
    final dueDateValue = json['dueDate'] as String?;

    return DittoTask(
      name: json['name'] as String,
      dueDate: dueDateValue == null ? null : DateTime.parse(dueDateValue),
      minimumMinutes: json['minimumMinutes'] as int,
      maximumMinutes: json['maximumMinutes'] as int,
      importance: TaskImportance.values.byName(json['importance'] as String),
    );
  }
}
