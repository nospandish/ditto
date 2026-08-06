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

    for (var taskIndex = 0; taskIndex < orderedTasks.length; taskIndex++) {
      final task = orderedTasks[taskIndex];
      final remainingMinimum = orderedTasks
          .skip(taskIndex + 1)
          .fold(0, (total, laterTask) => total + laterTask.minimumMinutes);
      final totalTimeLeft = _totalTimeLeft(windows, cursors);
      final desiredDuration = (totalTimeLeft - remainingMinimum).clamp(
        task.minimumMinutes,
        task.maximumMinutes,
      );
      final windowIndex = _bestWindowIndex(
        windows: windows,
        cursors: cursors,
        minimumDuration: task.minimumMinutes,
        desiredDuration: desiredDuration,
      );
      if (windowIndex == null) continue;

      final start = cursors[windowIndex];
      final roomInWindow = windows[windowIndex].endMinutes - start;
      final duration = desiredDuration.clamp(task.minimumMinutes, roomInWindow);
      final end = start + duration;
      schedule.add(
        ScheduledTask(task: task, startMinutes: start, endMinutes: end),
      );
      cursors[windowIndex] = end;
    }

    schedule.sort(
      (first, second) => first.startMinutes.compareTo(second.startMinutes),
    );
    return schedule;
  }

  int _totalTimeLeft(List<AvailableTimeBlock> windows, List<int> cursors) {
    var total = 0;
    for (var index = 0; index < windows.length; index++) {
      total += windows[index].endMinutes - cursors[index];
    }
    return total;
  }

  int? _bestWindowIndex({
    required List<AvailableTimeBlock> windows,
    required List<int> cursors,
    required int minimumDuration,
    required int desiredDuration,
  }) {
    int? bestIndex;
    var mostRoom = -1;

    for (var index = 0; index < windows.length; index++) {
      final room = windows[index].endMinutes - cursors[index];
      if (room < minimumDuration) continue;
      if (room >= desiredDuration) return index;
      if (room > mostRoom) {
        bestIndex = index;
        mostRoom = room;
      }
    }

    return bestIndex;
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
