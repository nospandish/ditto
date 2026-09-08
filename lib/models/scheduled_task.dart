import 'ditto_task.dart';

enum ScheduledTaskStatus { planned, completed, skipped }

class ScheduledTask {
  const ScheduledTask({
    required this.task,
    required this.startMinutes,
    required this.endMinutes,
    this.status = ScheduledTaskStatus.planned,
  });

  final DittoTask task;
  final int startMinutes;
  final int endMinutes;
  final ScheduledTaskStatus status;

  ScheduledTask copyWith({ScheduledTaskStatus? status}) {
    return ScheduledTask(
      task: task,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      status: status ?? this.status,
    );
  }

  int get durationMinutes => endMinutes - startMinutes;
}
