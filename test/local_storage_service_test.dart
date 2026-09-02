import 'dart:convert';

import 'package:ditto/models/available_time_block.dart';
import 'package:ditto/models/ditto_task.dart';
import 'package:ditto/models/saved_plan.dart';
import 'package:ditto/services/local_storage_service.dart';
import 'package:ditto/services/schedule_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const tasksKey = 'ditto.tasks.v1';
  const availableTimeKey = 'ditto.available_time.v1';
  const hasGeneratedPlanKey = 'ditto.has_generated_plan.v1';
  const savedPlansKey = 'ditto.saved_plans.v1';
  const activePlanIdKey = 'ditto.active_plan_id.v1';

  Future<(LocalStorageService, SharedPreferences)> createStorage([
    Map<String, Object> initialValues = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initialValues);
    final preferences = await SharedPreferences.getInstance();
    return (LocalStorageService(preferences), preferences);
  }

  test('empty storage returns empty lists', () async {
    final (storage, _) = await createStorage();

    expect(storage.loadTasks(), isEmpty);
    expect(storage.loadAvailableTime(), isEmpty);
    expect(storage.loadHasGeneratedPlan(), isFalse);
    expect(storage.loadPlans(), isEmpty);
    expect(storage.loadActivePlanId(), isNull);
  });

  test(
    'saves and loads tasks with every importance and optional dates',
    () async {
      final (storage, _) = await createStorage();
      final tasks = [
        const DittoTask(
          name: 'Optional task',
          minimumMinutes: 15,
          maximumMinutes: 30,
          importance: TaskImportance.optional,
        ),
        DittoTask(
          name: 'Can wait task',
          dueDate: DateTime(2026, 8, 25),
          minimumMinutes: 30,
          maximumMinutes: 60,
          importance: TaskImportance.canWait,
        ),
        DittoTask(
          name: 'Must complete task',
          dueDate: DateTime(2026, 8, 20, 17, 30),
          minimumMinutes: 60,
          maximumMinutes: 120,
          importance: TaskImportance.mustComplete,
        ),
      ];

      await storage.saveTasks(tasks);
      final loaded = storage.loadTasks();

      expect(loaded, hasLength(3));
      for (var index = 0; index < tasks.length; index++) {
        expect(loaded[index].name, tasks[index].name);
        expect(loaded[index].dueDate, tasks[index].dueDate);
        expect(loaded[index].minimumMinutes, tasks[index].minimumMinutes);
        expect(loaded[index].maximumMinutes, tasks[index].maximumMinutes);
        expect(loaded[index].importance, tasks[index].importance);
      }
    },
  );

  test('saves and loads available-time windows', () async {
    final (storage, _) = await createStorage();
    const blocks = [
      AvailableTimeBlock(startMinutes: 9 * 60, endMinutes: 10 * 60 + 15),
      AvailableTimeBlock(startMinutes: 14 * 60, endMinutes: 17 * 60),
    ];

    await storage.saveAvailableTime(blocks);
    final loaded = storage.loadAvailableTime();

    expect(loaded, hasLength(2));
    for (var index = 0; index < blocks.length; index++) {
      expect(loaded[index].startMinutes, blocks[index].startMinutes);
      expect(loaded[index].endMinutes, blocks[index].endMinutes);
    }
  });

  test('saving again replaces previously stored data', () async {
    final (storage, _) = await createStorage();
    const original = DittoTask(
      name: 'Original task',
      minimumMinutes: 30,
      maximumMinutes: 30,
      importance: TaskImportance.optional,
    );
    const replacement = DittoTask(
      name: 'Replacement task',
      minimumMinutes: 45,
      maximumMinutes: 60,
      importance: TaskImportance.mustComplete,
    );

    await storage.saveTasks([original]);
    await storage.saveTasks([replacement]);

    final loaded = storage.loadTasks();
    expect(loaded, hasLength(1));
    expect(loaded.single.name, 'Replacement task');
  });

  test('saves and loads whether a plan has been generated', () async {
    final (storage, _) = await createStorage();

    await storage.saveHasGeneratedPlan(true);
    expect(storage.loadHasGeneratedPlan(), isTrue);

    await storage.saveHasGeneratedPlan(false);
    expect(storage.loadHasGeneratedPlan(), isFalse);
  });

  test('saves and loads multiple plans and the selected plan', () async {
    final (storage, _) = await createStorage();
    const tasks = [
      DittoTask(
        name: 'Saved plan task',
        minimumMinutes: 30,
        maximumMinutes: 45,
        importance: TaskImportance.canWait,
      ),
    ];
    const time = [
      AvailableTimeBlock(startMinutes: 9 * 60, endMinutes: 10 * 60),
    ];
    final result = const ScheduleService().buildSchedule(
      tasks: tasks,
      availableTime: time,
    );
    final plans = [
      SavedPlan(
        id: 'first',
        name: 'Morning plan',
        createdAt: DateTime(2026, 9, 1, 9),
        tasks: tasks,
        availableTime: time,
        scheduleResult: result,
      ),
      SavedPlan(
        id: 'second',
        name: 'Later plan',
        createdAt: DateTime(2026, 9, 1, 10),
        tasks: tasks,
        availableTime: time,
        scheduleResult: result,
      ),
    ];

    await storage.savePlans(plans);
    await storage.saveActivePlanId('first');

    final loaded = storage.loadPlans();
    expect(loaded.map((plan) => plan.id), ['first', 'second']);
    expect(loaded.map((plan) => plan.name), ['Morning plan', 'Later plan']);
    expect(
      loaded.first.scheduleResult.scheduledTasks.single.task.name,
      'Saved plan task',
    );
    expect(storage.loadActivePlanId(), 'first');
  });

  test('malformed top-level data returns an empty list', () async {
    final (storage, _) = await createStorage({tasksKey: 'not valid JSON'});

    expect(storage.loadTasks(), isEmpty);
  });

  test('malformed records are skipped while valid records are kept', () async {
    const validBlock = AvailableTimeBlock(
      startMinutes: 8 * 60,
      endMinutes: 9 * 60,
    );
    final storedValue = jsonEncode([
      validBlock.toJson(),
      {'startMinutes': 'wrong type', 'endMinutes': 12 * 60},
      'not an object',
    ]);
    final (storage, _) = await createStorage({availableTimeKey: storedValue});

    final loaded = storage.loadAvailableTime();
    expect(loaded, hasLength(1));
    expect(loaded.single.startMinutes, validBlock.startMinutes);
    expect(loaded.single.endMinutes, validBlock.endMinutes);
  });

  test(
    'clearAllData removes Ditto data but preserves unrelated preferences',
    () async {
      final (storage, preferences) = await createStorage({
        tasksKey: '[]',
        availableTimeKey: '[]',
        hasGeneratedPlanKey: true,
        savedPlansKey: '[]',
        activePlanIdKey: 'saved-plan',
        'another_feature.setting': true,
      });

      await storage.clearAllData();

      expect(preferences.containsKey(tasksKey), isFalse);
      expect(preferences.containsKey(availableTimeKey), isFalse);
      expect(preferences.containsKey(hasGeneratedPlanKey), isFalse);
      expect(preferences.containsKey(savedPlansKey), isFalse);
      expect(preferences.containsKey(activePlanIdKey), isFalse);
      expect(preferences.getBool('another_feature.setting'), isTrue);
      expect(storage.loadTasks(), isEmpty);
      expect(storage.loadAvailableTime(), isEmpty);
    },
  );
}
