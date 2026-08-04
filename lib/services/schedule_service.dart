import '../models/available_time_block.dart';
import '../models/ditto_task.dart';
import '../models/scheduled_task.dart';

class ScheduleService {
  const ScheduleService();

  List<ScheduledTask> buildSchedule({
    required List<DittoTask> tasks,
    required List<AvailableTimeBlock> availableTime,
  }) {
    final orderedTasks = [...tasks]..sort(_compareTasks);
    final windows = [...availableTime]
      ..sort(
        (first, second) => first.startMinutes.compareTo(second.startMinutes),
      );
    final schedule = <ScheduledTask>[];
    final cursors = windows.map((window) => window.startMinutes).toList();

    for (final task in orderedTasks) {
      for (var windowIndex = 0; windowIndex < windows.length; windowIndex++) {
        final start = cursors[windowIndex];
        final end = start + task.minimumMinutes;
        if (end > windows[windowIndex].endMinutes) continue;

        schedule.add(
          ScheduledTask(task: task, startMinutes: start, endMinutes: end),
        );
        cursors[windowIndex] = end;
        break;
      }
    }

    return schedule;
  }

  int _compareTasks(DittoTask first, DittoTask second) {
    final importanceComparison = _importanceRank(
      first.importance,
    ).compareTo(_importanceRank(second.importance));
    if (importanceComparison != 0) return importanceComparison;

    if (first.dueDate == null && second.dueDate == null) return 0;
    if (first.dueDate == null) return 1;
    if (second.dueDate == null) return -1;
    return first.dueDate!.compareTo(second.dueDate!);
  }

  int _importanceRank(TaskImportance importance) => switch (importance) {
    TaskImportance.mustComplete => 0,
    TaskImportance.canWait => 1,
    TaskImportance.optional => 2,
  };
}
