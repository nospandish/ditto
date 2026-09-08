import 'ditto_task.dart';
import 'scheduled_task.dart';

enum ScheduleIssueReason {
  noAvailableTime,
  insufficientTotalTime,
  noContinuousWindow,
}

class ScheduleIssue {
  const ScheduleIssue({required this.task, required this.reason});

  final DittoTask task;
  final ScheduleIssueReason reason;
}

class ScheduleBuildResult {
  ScheduleBuildResult({
    required List<ScheduledTask> scheduledTasks,
    required List<DittoTask> unscheduledTasks,
    required List<ScheduleIssue> issues,
    required this.totalAvailableMinutes,
    required this.mustCompleteMinimumMinutes,
  }) : scheduledTasks = List.unmodifiable(scheduledTasks),
       unscheduledTasks = List.unmodifiable(unscheduledTasks),
       issues = List.unmodifiable(issues);

  final List<ScheduledTask> scheduledTasks;
  final List<DittoTask> unscheduledTasks;
  final List<ScheduleIssue> issues;
  final int totalAvailableMinutes;
  final int mustCompleteMinimumMinutes;

  ScheduleBuildResult copyWith({List<ScheduledTask>? scheduledTasks}) {
    return ScheduleBuildResult(
      scheduledTasks: scheduledTasks ?? this.scheduledTasks,
      unscheduledTasks: unscheduledTasks,
      issues: issues,
      totalAvailableMinutes: totalAvailableMinutes,
      mustCompleteMinimumMinutes: mustCompleteMinimumMinutes,
    );
  }

  bool get hasImpossibleMustCompleteTasks => issues.isNotEmpty;

  bool get isSuccessful => !hasImpossibleMustCompleteTasks;

  int get minutesShort {
    final difference = mustCompleteMinimumMinutes - totalAvailableMinutes;
    return difference > 0 ? difference : 0;
  }
}
