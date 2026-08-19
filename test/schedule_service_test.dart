import 'package:ditto/models/available_time_block.dart';
import 'package:ditto/models/ditto_task.dart';
import 'package:ditto/models/schedule_build_result.dart';
import 'package:ditto/services/schedule_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = ScheduleService();

  test('uses maximum durations when all tasks have enough time', () {
    const optional = DittoTask(
      name: 'Read',
      minimumMinutes: 30,
      maximumMinutes: 60,
      importance: TaskImportance.optional,
    );
    const required = DittoTask(
      name: 'Homework',
      minimumMinutes: 45,
      maximumMinutes: 90,
      importance: TaskImportance.mustComplete,
    );

    final result = service.buildSchedule(
      tasks: [optional, required],
      availableTime: [
        const AvailableTimeBlock(
          startMinutes: 9 * 60,
          endMinutes: 11 * 60 + 30,
        ),
      ],
    );

    expect(result.scheduledTasks.map((item) => item.task.name), [
      'Homework',
      'Read',
    ]);
    expect(result.scheduledTasks.first.startMinutes, 9 * 60);
    expect(result.scheduledTasks.first.durationMinutes, 90);
    expect(result.scheduledTasks.last.durationMinutes, 60);
    expect(result.isSuccessful, isTrue);
  });

  test('shrinks tasks toward minimum durations when time is limited', () {
    const first = DittoTask(
      name: 'Homework',
      minimumMinutes: 45,
      maximumMinutes: 90,
      importance: TaskImportance.mustComplete,
    );
    const second = DittoTask(
      name: 'Read',
      minimumMinutes: 30,
      maximumMinutes: 60,
      importance: TaskImportance.optional,
    );

    final result = service.buildSchedule(
      tasks: [first, second],
      availableTime: [
        const AvailableTimeBlock(startMinutes: 9 * 60, endMinutes: 11 * 60),
      ],
    );

    expect(result.scheduledTasks.map((item) => item.durationMinutes), [90, 30]);
  });

  test('skips tasks that do not fit and continues in the next window', () {
    const task = DittoTask(
      name: 'Practice',
      minimumMinutes: 45,
      maximumMinutes: 60,
      importance: TaskImportance.canWait,
    );

    final result = service.buildSchedule(
      tasks: [task],
      availableTime: [
        const AvailableTimeBlock(startMinutes: 9 * 60, endMinutes: 9 * 60 + 30),
        const AvailableTimeBlock(startMinutes: 13 * 60, endMinutes: 14 * 60),
      ],
    );

    expect(result.scheduledTasks.single.startMinutes, 13 * 60);
    expect(result.scheduledTasks.single.endMinutes, 14 * 60);
  });

  test('keeps a large window open for a task that needs it', () {
    final flexibleTask = DittoTask(
      name: 'Review notes',
      minimumMinutes: 60,
      maximumMinutes: 60,
      importance: TaskImportance.mustComplete,
      dueDate: DateTime(2026, 8, 6),
    );
    final largeTask = DittoTask(
      name: 'Practice exam',
      minimumMinutes: 120,
      maximumMinutes: 120,
      importance: TaskImportance.mustComplete,
      dueDate: DateTime(2026, 8, 7),
    );

    final result = service.buildSchedule(
      tasks: [flexibleTask, largeTask],
      availableTime: [
        const AvailableTimeBlock(startMinutes: 9 * 60, endMinutes: 11 * 60),
        const AvailableTimeBlock(startMinutes: 14 * 60, endMinutes: 15 * 60),
      ],
    );

    expect(result.scheduledTasks.map((item) => item.task.name), [
      'Practice exam',
      'Review notes',
    ]);
    expect(result.scheduledTasks.first.startMinutes, 9 * 60);
    expect(result.scheduledTasks.last.startMinutes, 14 * 60);
  });

  test('importance wins when every task cannot fit', () {
    const mustComplete = DittoTask(
      name: 'Submit application',
      minimumMinutes: 60,
      maximumMinutes: 60,
      importance: TaskImportance.mustComplete,
    );
    final optionalOne = DittoTask(
      name: 'Organize notes',
      minimumMinutes: 30,
      maximumMinutes: 30,
      importance: TaskImportance.optional,
      dueDate: DateTime(2026, 8, 6),
    );
    final optionalTwo = DittoTask(
      name: 'Clean desk',
      minimumMinutes: 30,
      maximumMinutes: 30,
      importance: TaskImportance.optional,
      dueDate: DateTime(2026, 8, 6),
    );

    final result = service.buildSchedule(
      tasks: [optionalOne, optionalTwo, mustComplete],
      availableTime: [
        const AvailableTimeBlock(startMinutes: 9 * 60, endMinutes: 10 * 60),
      ],
    );

    expect(result.scheduledTasks.single.task.name, 'Submit application');
  });

  test('an earlier deadline wins after importance', () {
    final later = DittoTask(
      name: 'Next week task',
      minimumMinutes: 60,
      maximumMinutes: 60,
      importance: TaskImportance.canWait,
      dueDate: DateTime(2026, 8, 12),
    );
    final earlier = DittoTask(
      name: 'Tomorrow task',
      minimumMinutes: 60,
      maximumMinutes: 60,
      importance: TaskImportance.canWait,
      dueDate: DateTime(2026, 8, 7),
    );

    final result = service.buildSchedule(
      tasks: [later, earlier],
      availableTime: [
        const AvailableTimeBlock(startMinutes: 9 * 60, endMinutes: 10 * 60),
      ],
    );

    expect(result.scheduledTasks.single.task.name, 'Tomorrow task');
  });

  test('task count breaks ties after importance and deadlines', () {
    const longTask = DittoTask(
      name: 'Long task',
      minimumMinutes: 60,
      maximumMinutes: 60,
      importance: TaskImportance.optional,
    );
    const shortOne = DittoTask(
      name: 'Short task one',
      minimumMinutes: 30,
      maximumMinutes: 30,
      importance: TaskImportance.optional,
    );
    const shortTwo = DittoTask(
      name: 'Short task two',
      minimumMinutes: 30,
      maximumMinutes: 30,
      importance: TaskImportance.optional,
    );

    final result = service.buildSchedule(
      tasks: [longTask, shortOne, shortTwo],
      availableTime: [
        const AvailableTimeBlock(startMinutes: 9 * 60, endMinutes: 10 * 60),
      ],
    );

    expect(result.scheduledTasks.map((item) => item.task.name), [
      'Short task one',
      'Short task two',
    ]);
  });

  test('reports a one-minute shortage for must-complete work', () {
    const first = DittoTask(
      name: 'Finish essay',
      minimumMinutes: 30,
      maximumMinutes: 30,
      importance: TaskImportance.mustComplete,
    );
    const second = DittoTask(
      name: 'Study vocabulary',
      minimumMinutes: 30,
      maximumMinutes: 30,
      importance: TaskImportance.mustComplete,
    );

    final result = service.buildSchedule(
      tasks: [first, second],
      availableTime: [
        const AvailableTimeBlock(startMinutes: 9 * 60, endMinutes: 9 * 60 + 59),
      ],
    );

    expect(result.hasImpossibleMustCompleteTasks, isTrue);
    expect(result.minutesShort, 1);
    expect(result.scheduledTasks, hasLength(1));
    expect(result.unscheduledTasks, hasLength(1));
    expect(
      result.issues.single.reason,
      ScheduleIssueReason.insufficientTotalTime,
    );
    expect(result.issues.single.task, same(result.unscheduledTasks.single));
  });

  test('reports fragmented time when total capacity is sufficient', () {
    const first = DittoTask(
      name: 'Complete lab',
      minimumMinutes: 40,
      maximumMinutes: 40,
      importance: TaskImportance.mustComplete,
    );
    const second = DittoTask(
      name: 'Practice speech',
      minimumMinutes: 40,
      maximumMinutes: 40,
      importance: TaskImportance.mustComplete,
    );

    final result = service.buildSchedule(
      tasks: [first, second],
      availableTime: const [
        AvailableTimeBlock(startMinutes: 9 * 60, endMinutes: 9 * 60 + 30),
        AvailableTimeBlock(startMinutes: 10 * 60, endMinutes: 10 * 60 + 50),
      ],
    );

    expect(result.hasImpossibleMustCompleteTasks, isTrue);
    expect(result.minutesShort, 0);
    expect(result.issues.single.reason, ScheduleIssueReason.noContinuousWindow);
  });

  test('remains successful when only optional work is omitted', () {
    const required = DittoTask(
      name: 'Submit assignment',
      minimumMinutes: 60,
      maximumMinutes: 60,
      importance: TaskImportance.mustComplete,
    );
    const optional = DittoTask(
      name: 'Organize notes',
      minimumMinutes: 60,
      maximumMinutes: 60,
      importance: TaskImportance.optional,
    );

    final result = service.buildSchedule(
      tasks: [optional, required],
      availableTime: const [
        AvailableTimeBlock(startMinutes: 9 * 60, endMinutes: 10 * 60),
      ],
    );

    expect(result.isSuccessful, isTrue);
    expect(result.issues, isEmpty);
    expect(result.scheduledTasks.single.task, same(required));
    expect(result.unscheduledTasks.single, same(optional));
  });

  test('reports no available time for must-complete work', () {
    const task = DittoTask(
      name: 'Turn in project',
      minimumMinutes: 45,
      maximumMinutes: 45,
      importance: TaskImportance.mustComplete,
    );

    final result = service.buildSchedule(
      tasks: [task],
      availableTime: const [],
    );

    expect(result.scheduledTasks, isEmpty);
    expect(result.issues.single.reason, ScheduleIssueReason.noAvailableTime);
    expect(result.issues.single.task, same(task));
  });

  test('becomes successful after enough availability is added', () {
    const first = DittoTask(
      name: 'Finish essay',
      minimumMinutes: 45,
      maximumMinutes: 45,
      importance: TaskImportance.mustComplete,
    );
    const second = DittoTask(
      name: 'Study notes',
      minimumMinutes: 30,
      maximumMinutes: 30,
      importance: TaskImportance.mustComplete,
    );

    final impossible = service.buildSchedule(
      tasks: [first, second],
      availableTime: const [
        AvailableTimeBlock(startMinutes: 9 * 60, endMinutes: 10 * 60),
      ],
    );
    final recovered = service.buildSchedule(
      tasks: [first, second],
      availableTime: const [
        AvailableTimeBlock(startMinutes: 9 * 60, endMinutes: 10 * 60 + 15),
      ],
    );

    expect(impossible.hasImpossibleMustCompleteTasks, isTrue);
    expect(recovered.isSuccessful, isTrue);
    expect(recovered.scheduledTasks, hasLength(2));
    expect(recovered.scheduledTasks.map((item) => item.task).toSet(), {
      first,
      second,
    });
  });
}
