import 'ditto_task.dart';

class ScheduledTask {
  const ScheduledTask({
    required this.task,
    required this.startMinutes,
    required this.endMinutes,
  });

  final DittoTask task;
  final int startMinutes;
  final int endMinutes;

  int get durationMinutes => endMinutes - startMinutes;
}
