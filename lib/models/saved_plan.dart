import 'available_time_block.dart';
import 'ditto_task.dart';
import 'schedule_build_result.dart';
import 'scheduled_task.dart';

class SavedPlan {
  SavedPlan({
    required this.id,
    required this.name,
    required this.createdAt,
    required List<DittoTask> tasks,
    required List<AvailableTimeBlock> availableTime,
    required this.scheduleResult,
  }) : tasks = List.unmodifiable(tasks),
       availableTime = List.unmodifiable(availableTime);

  final String id;
  final String name;
  final DateTime createdAt;
  final List<DittoTask> tasks;
  final List<AvailableTimeBlock> availableTime;
  final ScheduleBuildResult scheduleResult;

  SavedPlan copyWith({String? name}) {
    return SavedPlan(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      tasks: tasks,
      availableTime: availableTime,
      scheduleResult: scheduleResult,
    );
  }

  bool matchesInputs({
    required List<DittoTask> tasks,
    required List<AvailableTimeBlock> availableTime,
  }) {
    if (this.tasks.length != tasks.length ||
        this.availableTime.length != availableTime.length) {
      return false;
    }

    for (var index = 0; index < tasks.length; index++) {
      if (!_sameTask(this.tasks[index], tasks[index])) return false;
    }
    for (var index = 0; index < availableTime.length; index++) {
      if (!_sameTimeBlock(this.availableTime[index], availableTime[index])) {
        return false;
      }
    }
    return true;
  }

  Map<String, dynamic> toJson() {
    int taskIndex(DittoTask task) {
      final index = tasks.indexWhere((candidate) => identical(candidate, task));
      if (index == -1) {
        throw StateError('A saved plan item does not reference its task list.');
      }
      return index;
    }

    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'availableTime': availableTime.map((block) => block.toJson()).toList(),
      'scheduledTasks': [
        for (final item in scheduleResult.scheduledTasks)
          {
            'taskIndex': taskIndex(item.task),
            'startMinutes': item.startMinutes,
            'endMinutes': item.endMinutes,
          },
      ],
      'unscheduledTaskIndexes': [
        for (final task in scheduleResult.unscheduledTasks) taskIndex(task),
      ],
      'issues': [
        for (final issue in scheduleResult.issues)
          {'taskIndex': taskIndex(issue.task), 'reason': issue.reason.name},
      ],
      'totalAvailableMinutes': scheduleResult.totalAvailableMinutes,
      'mustCompleteMinimumMinutes': scheduleResult.mustCompleteMinimumMinutes,
    };
  }

  factory SavedPlan.fromJson(Map<String, dynamic> json) {
    final taskValues = json['tasks'];
    final timeValues = json['availableTime'];
    final scheduledValues = json['scheduledTasks'];
    final unscheduledValues = json['unscheduledTaskIndexes'];
    final issueValues = json['issues'];
    if (taskValues is! List ||
        timeValues is! List ||
        scheduledValues is! List ||
        unscheduledValues is! List ||
        issueValues is! List) {
      throw const FormatException('Saved plan lists are invalid.');
    }

    final tasks = [
      for (final value in taskValues)
        DittoTask.fromJson(Map<String, dynamic>.from(value as Map)),
    ];
    final availableTime = [
      for (final value in timeValues)
        AvailableTimeBlock.fromJson(Map<String, dynamic>.from(value as Map)),
    ];

    DittoTask taskAt(Object? value) {
      if (value is! int || value < 0 || value >= tasks.length) {
        throw const FormatException('Saved plan task index is invalid.');
      }
      return tasks[value];
    }

    final scheduledTasks = [
      for (final value in scheduledValues)
        ScheduledTask(
          task: taskAt((value as Map)['taskIndex']),
          startMinutes: value['startMinutes'] as int,
          endMinutes: value['endMinutes'] as int,
        ),
    ];
    final unscheduledTasks = [
      for (final value in unscheduledValues) taskAt(value),
    ];
    final issues = [
      for (final value in issueValues)
        ScheduleIssue(
          task: taskAt((value as Map)['taskIndex']),
          reason: ScheduleIssueReason.values.byName(value['reason'] as String),
        ),
    ];

    return SavedPlan(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Saved plan',
      createdAt: DateTime.parse(json['createdAt'] as String),
      tasks: tasks,
      availableTime: availableTime,
      scheduleResult: ScheduleBuildResult(
        scheduledTasks: scheduledTasks,
        unscheduledTasks: unscheduledTasks,
        issues: issues,
        totalAvailableMinutes: json['totalAvailableMinutes'] as int,
        mustCompleteMinimumMinutes: json['mustCompleteMinimumMinutes'] as int,
      ),
    );
  }
}

bool _sameTask(DittoTask first, DittoTask second) {
  return first.name == second.name &&
      first.dueDate == second.dueDate &&
      first.minimumMinutes == second.minimumMinutes &&
      first.maximumMinutes == second.maximumMinutes &&
      first.importance == second.importance;
}

bool _sameTimeBlock(AvailableTimeBlock first, AvailableTimeBlock second) {
  return first.startMinutes == second.startMinutes &&
      first.endMinutes == second.endMinutes;
}
