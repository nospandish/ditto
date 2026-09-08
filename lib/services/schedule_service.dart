import '../models/available_time_block.dart';
import '../models/ditto_task.dart';
import '../models/schedule_build_result.dart';
import '../models/scheduled_task.dart';

class ScheduleService {
  const ScheduleService();

  ScheduleBuildResult buildSchedule({
    required List<DittoTask> tasks,
    required List<AvailableTimeBlock> availableTime,
  }) {
    final totalAvailableMinutes = availableTime.fold(
      0,
      (total, window) => total + window.durationMinutes,
    );
    final mustCompleteMinimumMinutes = tasks
        .where((task) => task.importance == TaskImportance.mustComplete)
        .fold(0, (total, task) => total + task.minimumMinutes);

    if (tasks.isEmpty || availableTime.isEmpty) {
      return _buildResult(
        tasks: tasks,
        schedule: const [],
        totalAvailableMinutes: totalAvailableMinutes,
        mustCompleteMinimumMinutes: mustCompleteMinimumMinutes,
      );
    }

    final windows = [...availableTime]
      ..sort(
        (first, second) => first.startMinutes.compareTo(second.startMinutes),
      );
    final candidates = _buildCandidates(tasks);
    final selectedIndexes = _selectTasks(candidates, windows);
    final selectedTasks = [
      for (final index in selectedIndexes) candidates[index],
    ];
    final assignment = _assignTasks(selectedTasks, windows);

    final schedule = assignment == null
        ? const <ScheduledTask>[]
        : _buildTimedSchedule(selectedTasks, assignment, windows);
    return _buildResult(
      tasks: tasks,
      schedule: schedule,
      totalAvailableMinutes: totalAvailableMinutes,
      mustCompleteMinimumMinutes: mustCompleteMinimumMinutes,
    );
  }

  ScheduleBuildResult buildRemainingSchedule({
    required List<DittoTask> tasks,
    required List<AvailableTimeBlock> availableTime,
    required int currentMinutes,
  }) {
    final remainingTime = [
      for (final block in availableTime)
        if (block.endMinutes > currentMinutes)
          AvailableTimeBlock(
            startMinutes: block.startMinutes < currentMinutes
                ? currentMinutes
                : block.startMinutes,
            endMinutes: block.endMinutes,
          ),
    ];
    return buildSchedule(tasks: tasks, availableTime: remainingTime);
  }

  ScheduleBuildResult _buildResult({
    required List<DittoTask> tasks,
    required List<ScheduledTask> schedule,
    required int totalAvailableMinutes,
    required int mustCompleteMinimumMinutes,
  }) {
    final scheduledTasks = {for (final item in schedule) item.task};
    final unscheduledTasks = tasks
        .where((task) => !scheduledTasks.contains(task))
        .toList(growable: false);
    final unscheduledMustComplete = unscheduledTasks.where(
      (task) => task.importance == TaskImportance.mustComplete,
    );
    final issueReason = switch ((
      totalAvailableMinutes,
      mustCompleteMinimumMinutes > totalAvailableMinutes,
    )) {
      (0, _) => ScheduleIssueReason.noAvailableTime,
      (_, true) => ScheduleIssueReason.insufficientTotalTime,
      _ => ScheduleIssueReason.noContinuousWindow,
    };

    return ScheduleBuildResult(
      scheduledTasks: schedule,
      unscheduledTasks: unscheduledTasks,
      issues: [
        for (final task in unscheduledMustComplete)
          ScheduleIssue(task: task, reason: issueReason),
      ],
      totalAvailableMinutes: totalAvailableMinutes,
      mustCompleteMinimumMinutes: mustCompleteMinimumMinutes,
    );
  }

  List<_TaskCandidate> _buildCandidates(List<DittoTask> tasks) {
    final deadlineDays = <int>{
      for (final task in tasks)
        if (task.dueDate != null) _dateOnlyValue(task.dueDate!),
    }.toList()..sort();
    final deadlineRanks = {
      for (var index = 0; index < deadlineDays.length; index++)
        deadlineDays[index]: index,
    };
    final deadlineBase = BigInt.from(tasks.length + 1);

    final candidates = <_TaskCandidate>[];
    for (var index = 0; index < tasks.length; index++) {
      final task = tasks[index];
      var deadlineScore = BigInt.zero;
      if (task.dueDate != null) {
        final rank = deadlineRanks[_dateOnlyValue(task.dueDate!)]!;
        deadlineScore = deadlineBase.pow(deadlineDays.length - rank - 1);
      }
      candidates.add(
        _TaskCandidate(
          task: task,
          originalIndex: index,
          deadlineScore: deadlineScore,
        ),
      );
    }

    candidates.sort(_compareCandidates);
    return candidates;
  }

  List<int> _selectTasks(
    List<_TaskCandidate> candidates,
    List<AvailableTimeBlock> windows,
  ) {
    final capacities = windows.map((window) => window.durationMinutes).toList()
      ..sort((first, second) => second.compareTo(first));
    final memo = <String, _SelectionResult>{};

    _SelectionResult search(int taskIndex, List<int> remaining) {
      if (taskIndex == candidates.length) return _SelectionResult.empty();

      final key = '$taskIndex|${remaining.join(',')}';
      final cached = memo[key];
      if (cached != null) return cached;

      var best = search(taskIndex + 1, remaining);
      final candidate = candidates[taskIndex];
      final triedCapacities = <int>{};

      for (var windowIndex = 0; windowIndex < remaining.length; windowIndex++) {
        final capacity = remaining[windowIndex];
        if (capacity < candidate.task.minimumMinutes ||
            !triedCapacities.add(capacity)) {
          continue;
        }

        final nextRemaining = [...remaining];
        nextRemaining[windowIndex] -= candidate.task.minimumMinutes;
        nextRemaining.sort((first, second) => second.compareTo(first));
        final included = search(
          taskIndex + 1,
          nextRemaining,
        ).withTask(taskIndex, candidate);

        if (included.score.isBetterThan(best.score)) best = included;
      }

      memo[key] = best;
      return best;
    }

    return search(0, capacities).taskIndexes;
  }

  _AssignmentResult? _assignTasks(
    List<_TaskCandidate> tasks,
    List<AvailableTimeBlock> windows,
  ) {
    final initialRemaining = windows
        .map((window) => window.durationMinutes)
        .toList();
    final initialExpandable = List<int>.filled(windows.length, 0);
    final memo = <String, _AssignmentResult?>{};

    _AssignmentResult? search(
      int taskIndex,
      List<int> remaining,
      List<int> expandable,
    ) {
      if (taskIndex == tasks.length) {
        var extraMinutes = 0;
        for (var index = 0; index < windows.length; index++) {
          extraMinutes += _minimum(remaining[index], expandable[index]);
        }
        return _AssignmentResult(
          extraMinutes: extraMinutes,
          windowIndexes: const [],
        );
      }

      final key = '$taskIndex|${remaining.join(',')}|${expandable.join(',')}';
      if (memo.containsKey(key)) return memo[key];

      final task = tasks[taskIndex].task;
      _AssignmentResult? best;

      for (var windowIndex = 0; windowIndex < windows.length; windowIndex++) {
        if (remaining[windowIndex] < task.minimumMinutes) continue;

        final nextRemaining = [...remaining];
        final nextExpandable = [...expandable];
        nextRemaining[windowIndex] -= task.minimumMinutes;
        nextExpandable[windowIndex] += _maximum(
          0,
          task.maximumMinutes - task.minimumMinutes,
        );
        final future = search(taskIndex + 1, nextRemaining, nextExpandable);
        if (future == null) continue;

        final result = _AssignmentResult(
          extraMinutes: future.extraMinutes,
          windowIndexes: [windowIndex, ...future.windowIndexes],
        );
        if (best == null || result.extraMinutes > best.extraMinutes) {
          best = result;
        }
      }

      memo[key] = best;
      return best;
    }

    return search(0, initialRemaining, initialExpandable);
  }

  List<ScheduledTask> _buildTimedSchedule(
    List<_TaskCandidate> tasks,
    _AssignmentResult assignment,
    List<AvailableTimeBlock> windows,
  ) {
    final tasksByWindow = List.generate(
      windows.length,
      (_) => <_TaskCandidate>[],
    );
    for (var index = 0; index < tasks.length; index++) {
      tasksByWindow[assignment.windowIndexes[index]].add(tasks[index]);
    }

    final schedule = <ScheduledTask>[];
    for (var windowIndex = 0; windowIndex < windows.length; windowIndex++) {
      final windowTasks = tasksByWindow[windowIndex]..sort(_compareCandidates);
      final minimumTime = windowTasks.fold(
        0,
        (total, candidate) => total + candidate.task.minimumMinutes,
      );
      var extraTime = windows[windowIndex].durationMinutes - minimumTime;
      var cursor = windows[windowIndex].startMinutes;

      for (final candidate in windowTasks) {
        final task = candidate.task;
        final availableExtra = _maximum(
          0,
          task.maximumMinutes - task.minimumMinutes,
        );
        final taskExtra = _minimum(availableExtra, extraTime);
        final duration = task.minimumMinutes + taskExtra;
        schedule.add(
          ScheduledTask(
            task: task,
            startMinutes: cursor,
            endMinutes: cursor + duration,
          ),
        );
        cursor += duration;
        extraTime -= taskExtra;
      }
    }

    return schedule;
  }

  int _compareCandidates(_TaskCandidate first, _TaskCandidate second) {
    final taskComparison = _compareTasks(first.task, second.task);
    if (taskComparison != 0) return taskComparison;
    return first.originalIndex.compareTo(second.originalIndex);
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

  int _dateOnlyValue(DateTime date) =>
      DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;

  int _minimum(int first, int second) => first < second ? first : second;

  int _maximum(int first, int second) => first > second ? first : second;
}

class _TaskCandidate {
  const _TaskCandidate({
    required this.task,
    required this.originalIndex,
    required this.deadlineScore,
  });

  final DittoTask task;
  final int originalIndex;
  final BigInt deadlineScore;
}

class _SelectionScore {
  _SelectionScore({
    required this.mustCompleteCount,
    required this.canWaitCount,
    required this.deadlineScore,
    required this.taskCount,
  });

  _SelectionScore.empty()
    : mustCompleteCount = 0,
      canWaitCount = 0,
      deadlineScore = BigInt.zero,
      taskCount = 0;

  final int mustCompleteCount;
  final int canWaitCount;
  final BigInt deadlineScore;
  final int taskCount;

  _SelectionScore withTask(_TaskCandidate candidate) {
    return _SelectionScore(
      mustCompleteCount:
          mustCompleteCount +
          (candidate.task.importance == TaskImportance.mustComplete ? 1 : 0),
      canWaitCount:
          canWaitCount +
          (candidate.task.importance == TaskImportance.canWait ? 1 : 0),
      deadlineScore: deadlineScore + candidate.deadlineScore,
      taskCount: taskCount + 1,
    );
  }

  bool isBetterThan(_SelectionScore other) {
    if (mustCompleteCount != other.mustCompleteCount) {
      return mustCompleteCount > other.mustCompleteCount;
    }
    if (canWaitCount != other.canWaitCount) {
      return canWaitCount > other.canWaitCount;
    }
    final deadlineComparison = deadlineScore.compareTo(other.deadlineScore);
    if (deadlineComparison != 0) return deadlineComparison > 0;
    return taskCount > other.taskCount;
  }
}

class _SelectionResult {
  _SelectionResult({required this.score, required this.taskIndexes});

  _SelectionResult.empty()
    : score = _SelectionScore.empty(),
      taskIndexes = const [];

  final _SelectionScore score;
  final List<int> taskIndexes;

  _SelectionResult withTask(int taskIndex, _TaskCandidate candidate) {
    return _SelectionResult(
      score: score.withTask(candidate),
      taskIndexes: [taskIndex, ...taskIndexes],
    );
  }
}

class _AssignmentResult {
  const _AssignmentResult({
    required this.extraMinutes,
    required this.windowIndexes,
  });

  final int extraMinutes;
  final List<int> windowIndexes;
}
