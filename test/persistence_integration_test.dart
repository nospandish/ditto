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
}
