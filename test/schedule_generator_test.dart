import 'dart:math';

import 'package:ditto/models/available_time_block.dart';
import 'package:ditto/models/ditto_task.dart';
import 'package:ditto/models/scheduled_task.dart';
import 'package:ditto/services/schedule_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = ScheduleService();
  const scenarioCount = 100;
  const seedOption = String.fromEnvironment('SCHEDULE_SEED');
  final providedSeed = seedOption.isEmpty ? null : int.tryParse(seedOption);

  if (seedOption.isNotEmpty && providedSeed == null) {
    throw ArgumentError.value(
      seedOption,
      'SCHEDULE_SEED',
      'The schedule seed must be an integer.',
    );
  }

  final firstSeed = providedSeed ?? Random.secure().nextInt(1 << 32);

  test('generated feasible schedules are valid (first seed: $firstSeed)', () {
    for (var scenario = 0; scenario < scenarioCount; scenario++) {
      final seed = firstSeed + scenario;
      final generated = _generateFeasibleSchedule(seed);
      final result = service.buildSchedule(
        tasks: generated.tasks,
        availableTime: generated.availableTime,
      );

      _expectValidFullPlan(result, generated, seed);
    }
  });
}

_GeneratedSchedule _generateFeasibleSchedule(int seed) {
  final random = Random(seed);
  final tasks = <DittoTask>[];
  final actualMinutesByTask = <String, int>{};
  final availableTime = <AvailableTimeBlock>[];
  final windowCount = 1 + random.nextInt(3);
  var windowStart = 8 * 60 + random.nextInt(5) * 15;

  for (var windowIndex = 0; windowIndex < windowCount; windowIndex++) {
    final taskCount = 1 + random.nextInt(3);
    var windowDuration = 0;

    for (var taskIndex = 0; taskIndex < taskCount; taskIndex++) {
      final actualMinutes = 30 + random.nextInt(4) * 15;
      final minimumReductionSteps = 1 + random.nextInt(actualMinutes ~/ 15 - 1);
      final maximumIncreaseSteps = 1 + random.nextInt(3);
      final name = 'Task $seed-$windowIndex-$taskIndex';
      final task = DittoTask(
        name: name,
        minimumMinutes: actualMinutes - minimumReductionSteps * 15,
        maximumMinutes: actualMinutes + maximumIncreaseSteps * 15,
        importance:
            TaskImportance.values[random.nextInt(TaskImportance.values.length)],
        dueDate: random.nextBool()
            ? DateTime(2026, 8, 12 + random.nextInt(14))
            : null,
      );

      tasks.add(task);
      actualMinutesByTask[name] = actualMinutes;
      windowDuration += actualMinutes;
    }

    availableTime.add(
      AvailableTimeBlock(
        startMinutes: windowStart,
        endMinutes: windowStart + windowDuration,
      ),
    );
    windowStart += windowDuration + 30 + random.nextInt(4) * 15;
  }

  tasks.shuffle(random);
  availableTime.shuffle(random);

  return _GeneratedSchedule(
    tasks: tasks,
    availableTime: availableTime,
    actualMinutesByTask: actualMinutesByTask,
  );
}

void _expectValidFullPlan(
  List<ScheduledTask> result,
  _GeneratedSchedule generated,
  int seed,
) {
  final reason = 'Generated scenario with seed $seed';

  for (final task in generated.tasks) {
    final actualMinutes = generated.actualMinutesByTask[task.name]!;
    expect(
      actualMinutes >= task.minimumMinutes &&
          actualMinutes <= task.maximumMinutes,
      isTrue,
      reason: '$reason did not generate a range containing the actual time',
    );
  }

  expect(result, hasLength(generated.tasks.length), reason: reason);
  for (final task in generated.tasks) {
    expect(
      result.where((scheduled) => identical(scheduled.task, task)),
      hasLength(1),
      reason: '$reason did not schedule ${task.name} exactly once',
    );
  }

  for (var index = 0; index < result.length; index++) {
    final scheduled = result[index];
    expect(
      scheduled.durationMinutes >= scheduled.task.minimumMinutes &&
          scheduled.durationMinutes <= scheduled.task.maximumMinutes,
      isTrue,
      reason: '$reason gave ${scheduled.task.name} an invalid duration',
    );
    expect(
      generated.availableTime.any(
        (window) =>
            scheduled.startMinutes >= window.startMinutes &&
            scheduled.endMinutes <= window.endMinutes,
      ),
      isTrue,
      reason: '$reason placed ${scheduled.task.name} outside available time',
    );

    if (index > 0) {
      expect(
        result[index - 1].endMinutes <= scheduled.startMinutes,
        isTrue,
        reason: '$reason contains overlapping or out-of-order tasks',
      );
    }
  }

  final scheduledMinutes = result.fold(
    0,
    (total, scheduled) => total + scheduled.durationMinutes,
  );
  final availableMinutes = generated.availableTime.fold(
    0,
    (total, window) => total + window.durationMinutes,
  );
  expect(
    scheduledMinutes,
    availableMinutes,
    reason: '$reason did not fill all generated available time',
  );
}

class _GeneratedSchedule {
  const _GeneratedSchedule({
    required this.tasks,
    required this.availableTime,
    required this.actualMinutesByTask,
  });

  final List<DittoTask> tasks;
  final List<AvailableTimeBlock> availableTime;
  final Map<String, int> actualMinutesByTask;
}
