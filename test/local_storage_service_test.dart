import 'dart:convert';

import 'package:ditto/models/available_time_block.dart';
import 'package:ditto/models/ditto_task.dart';
import 'package:ditto/services/local_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const tasksKey = 'ditto.tasks.v1';
  const availableTimeKey = 'ditto.available_time.v1';
  const hasGeneratedPlanKey = 'ditto.has_generated_plan.v1';

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
        'another_feature.setting': true,
      });

      await storage.clearAllData();

      expect(preferences.containsKey(tasksKey), isFalse);
      expect(preferences.containsKey(availableTimeKey), isFalse);
      expect(preferences.containsKey(hasGeneratedPlanKey), isFalse);
      expect(preferences.getBool('another_feature.setting'), isTrue);
      expect(storage.loadTasks(), isEmpty);
      expect(storage.loadAvailableTime(), isEmpty);
    },
  );
}
