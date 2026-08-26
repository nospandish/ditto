import 'dart:convert';

import 'package:ditto/app/app.dart';
import 'package:ditto/models/available_time_block.dart';
import 'package:ditto/models/ditto_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('loads saved tasks and available time during startup', (
    tester,
  ) async {
    const task = DittoTask(
      name: 'Saved science project',
      minimumMinutes: 45,
      maximumMinutes: 90,
      importance: TaskImportance.mustComplete,
    );
    const block = AvailableTimeBlock(startMinutes: 9 * 60, endMinutes: 12 * 60);
    SharedPreferences.setMockInitialValues({
      'ditto.tasks.v1': jsonEncode([task.toJson()]),
      'ditto.available_time.v1': jsonEncode([block.toJson()]),
    });
    await tester.pumpWidget(const DittoApp());
    expect(find.byKey(const Key('storage-loading')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Ready to plan your day'), findsOneWidget);
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    expect(find.text('Saved science project'), findsOneWidget);
    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();
    expect(find.textContaining('9:00 AM'), findsOneWidget);
  });

  testWidgets('saves a newly added task', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const DittoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a task'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-name-field')),
      'Persist this task',
    );
    final saveButton = find.byKey(const Key('save-task-button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString('ditto.tasks.v1');
    expect(stored, isNotNull);
    expect(stored, contains('Persist this task'));
  });

  testWidgets('restores a previously generated schedule during startup', (
    tester,
  ) async {
    const task = DittoTask(
      name: 'Restored schedule task',
      minimumMinutes: 45,
      maximumMinutes: 60,
      importance: TaskImportance.mustComplete,
    );
    const block = AvailableTimeBlock(startMinutes: 9 * 60, endMinutes: 11 * 60);
    SharedPreferences.setMockInitialValues({
      'ditto.tasks.v1': jsonEncode([task.toJson()]),
      'ditto.available_time.v1': jsonEncode([block.toJson()]),
      'ditto.has_generated_plan.v1': true,
    });
    await tester.pumpWidget(const DittoApp());
    await tester.pumpAndSettle();
    expect(find.text('Restored schedule task'), findsOneWidget);
    expect(find.textContaining('9:00 AM - 10:00 AM'), findsOneWidget);
    expect(find.text('Regenerate'), findsOneWidget);
  });

  testWidgets('records when the user generates a plan', (tester) async {
    const task = DittoTask(
      name: 'Generate saved plan',
      minimumMinutes: 30,
      maximumMinutes: 30,
      importance: TaskImportance.canWait,
    );
    const block = AvailableTimeBlock(
      startMinutes: 13 * 60,
      endMinutes: 14 * 60,
    );
    SharedPreferences.setMockInitialValues({
      'ditto.tasks.v1': jsonEncode([task.toJson()]),
      'ditto.available_time.v1': jsonEncode([block.toJson()]),
    });
    await tester.pumpWidget(const DittoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generate'));
    await tester.pumpAndSettle();
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('ditto.has_generated_plan.v1'), isTrue);
  });

  testWidgets('keeps an invalid schedule until a valid regeneration', (
    tester,
  ) async {
    const firstTask = DittoTask(
      name: 'First required task',
      minimumMinutes: 30,
      maximumMinutes: 30,
      importance: TaskImportance.mustComplete,
    );
    const secondTask = DittoTask(
      name: 'Second required task',
      minimumMinutes: 30,
      maximumMinutes: 30,
      importance: TaskImportance.mustComplete,
    );
    const block = AvailableTimeBlock(
      startMinutes: 9 * 60,
      endMinutes: 9 * 60 + 45,
    );
    SharedPreferences.setMockInitialValues({
      'ditto.tasks.v1': jsonEncode([firstTask.toJson(), secondTask.toJson()]),
      'ditto.available_time.v1': jsonEncode([block.toJson()]),
    });
    await tester.pumpWidget(const DittoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('generate-plan-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();
    expect(find.text('Add 15 min more.'), findsOneWidget);
    final editTime = find.byKey(const ValueKey('edit-time-block-0'));
    await tester.scrollUntilVisible(
      editTime,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(editTime);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('increase-end-time')));
    await tester.tap(find.byKey(const Key('save-time-block-button')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 1000));
    await tester.pumpAndSettle();
    expect(
      find.text('Your changes may fit. Regenerate to confirm.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('Not every required task fits'), findsOneWidget);
    await tester.tap(find.byKey(const Key('generate-plan-button')));
    await tester.pumpAndSettle();
    expect(find.text('Not every required task fits'), findsNothing);
    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('schedule-shortage-notice')), findsNothing);
  });
}
