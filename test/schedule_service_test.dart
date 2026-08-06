import 'package:ditto/models/available_time_block.dart';
import 'package:ditto/models/ditto_task.dart';
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

    expect(result.map((item) => item.task.name), ['Homework', 'Read']);
    expect(result.first.startMinutes, 9 * 60);
    expect(result.first.durationMinutes, 90);
    expect(result.last.durationMinutes, 60);
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

    expect(result.map((item) => item.durationMinutes), [90, 30]);
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

    expect(result.single.startMinutes, 13 * 60);
    expect(result.single.endMinutes, 14 * 60);
  });
}
