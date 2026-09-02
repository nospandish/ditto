import 'dart:convert';

import 'package:ditto/models/available_time_block.dart';
import 'package:ditto/models/ditto_task.dart';
import 'package:ditto/models/saved_plan.dart';
import 'package:ditto/services/schedule_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips an exact generated plan through JSON', () {
    const tasks = [
      DittoTask(
        name: 'Required project',
        minimumMinutes: 60,
        maximumMinutes: 90,
        importance: TaskImportance.mustComplete,
      ),
      DittoTask(
        name: 'Optional reading',
        minimumMinutes: 30,
        maximumMinutes: 30,
        importance: TaskImportance.optional,
      ),
    ];
    const availableTime = [
      AvailableTimeBlock(startMinutes: 9 * 60, endMinutes: 10 * 60),
    ];
    final result = const ScheduleService().buildSchedule(
      tasks: tasks,
      availableTime: availableTime,
    );
    final original = SavedPlan(
      id: 'plan-1',
      name: 'School day',
      createdAt: DateTime(2026, 9, 1, 14, 30),
      tasks: tasks,
      availableTime: availableTime,
      scheduleResult: result,
    );

    final decoded = jsonDecode(jsonEncode(original.toJson()));
    final restored = SavedPlan.fromJson(decoded as Map<String, dynamic>);

    expect(restored.id, original.id);
    expect(restored.name, original.name);
    expect(restored.createdAt, original.createdAt);
    expect(restored.tasks.map((task) => task.name), [
      'Required project',
      'Optional reading',
    ]);
    expect(restored.availableTime.single.startMinutes, 9 * 60);
    expect(restored.scheduleResult.scheduledTasks, hasLength(1));
    expect(
      restored.scheduleResult.scheduledTasks.single.task.name,
      'Required project',
    );
    expect(restored.scheduleResult.scheduledTasks.single.startMinutes, 9 * 60);
    expect(restored.scheduleResult.scheduledTasks.single.endMinutes, 10 * 60);
    expect(
      restored.scheduleResult.unscheduledTasks.single.name,
      'Optional reading',
    );
  });

  test('detects when current task or time inputs differ from its snapshot', () {
    const task = DittoTask(
      name: 'Original task',
      minimumMinutes: 30,
      maximumMinutes: 60,
      importance: TaskImportance.canWait,
    );
    const time = AvailableTimeBlock(startMinutes: 13 * 60, endMinutes: 15 * 60);
    final plan = SavedPlan(
      id: 'plan-1',
      name: 'Original plan',
      createdAt: DateTime(2026, 9, 1),
      tasks: const [task],
      availableTime: const [time],
      scheduleResult: const ScheduleService().buildSchedule(
        tasks: const [task],
        availableTime: const [time],
      ),
    );

    expect(
      plan.matchesInputs(tasks: const [task], availableTime: const [time]),
      isTrue,
    );
    expect(
      plan.matchesInputs(
        tasks: const [
          DittoTask(
            name: 'Edited task',
            minimumMinutes: 30,
            maximumMinutes: 60,
            importance: TaskImportance.canWait,
          ),
        ],
        availableTime: const [time],
      ),
      isFalse,
    );
    expect(
      plan.matchesInputs(
        tasks: const [task],
        availableTime: const [
          AvailableTimeBlock(startMinutes: 13 * 60, endMinutes: 16 * 60),
        ],
      ),
      isFalse,
    );
  });
}
