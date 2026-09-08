import 'dart:convert';

import 'package:ditto/app/app.dart';
import 'package:ditto/models/available_time_block.dart';
import 'package:ditto/models/ditto_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> generatePlan(WidgetTester tester, String name) async {
    await tester.tap(find.byKey(const Key('generate-plan-button')));
    await tester.pumpAndSettle();
    expect(find.text('Name this plan'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('plan-name-field')), name);
    await tester.tap(find.byKey(const Key('confirm-plan-name')));
    await tester.pumpAndSettle();
  }

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
    if (!tester.any(saveButton)) {
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();
    }
    tester.widget<FilledButton>(saveButton).onPressed!();
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
    expect(find.text('9:00 AM'), findsOneWidget);
    expect(find.text('10:00 AM'), findsOneWidget);
    expect(find.text('New plan'), findsOneWidget);
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
    await generatePlan(tester, 'Afternoon plan');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('ditto.has_generated_plan.v1'), isTrue);
    expect(
      preferences.getString('ditto.saved_plans.v1'),
      contains('Afternoon plan'),
    );
  });

  testWidgets(
    'marks scheduled tasks done or skipped and restores their status',
    (tester) async {
      const completedTask = DittoTask(
        name: 'Finish lab notes',
        minimumMinutes: 30,
        maximumMinutes: 30,
        importance: TaskImportance.mustComplete,
      );
      const skippedTask = DittoTask(
        name: 'Review extra examples',
        minimumMinutes: 30,
        maximumMinutes: 30,
        importance: TaskImportance.optional,
      );
      const block = AvailableTimeBlock(
        startMinutes: 13 * 60,
        endMinutes: 15 * 60,
      );
      SharedPreferences.setMockInitialValues({
        'ditto.tasks.v1': jsonEncode([
          completedTask.toJson(),
          skippedTask.toJson(),
        ]),
        'ditto.available_time.v1': jsonEncode([block.toJson()]),
      });

      await tester.pumpWidget(const DittoApp());
      await tester.pumpAndSettle();
      await generatePlan(tester, 'Status plan');

      await tester.tap(
        find.byKey(
          const ValueKey('status-menu-schedule-task-Finish lab notes'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('status-option-done-Finish lab notes')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('status-menu-schedule-task-Review extra examples'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('status-option-skip-Review extra examples')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Skip this task?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-skip-schedule-task')));
      await tester.pumpAndSettle();

      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Skipped'), findsOneWidget);

      final preferences = await SharedPreferences.getInstance();
      final storedPlans = preferences.getString('ditto.saved_plans.v1');
      expect(storedPlans, contains('"status":"completed"'));
      expect(storedPlans, contains('"status":"skipped"'));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(const DittoApp());
      await tester.pumpAndSettle();

      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Skipped'), findsOneWidget);
      await tester.tap(
        find.byKey(
          const ValueKey('status-menu-schedule-task-Finish lab notes'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('undo-schedule-task-Finish lab notes')),
        findsOneWidget,
      );
    },
  );

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
    await generatePlan(tester, 'Short day');
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
    expect(find.byKey(const Key('schedule-shortage-notice')), findsNothing);
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('Not every required task fits'), findsOneWidget);
    expect(find.byKey(const Key('outdated-plan-notice')), findsOneWidget);
    await generatePlan(tester, 'Longer day');
    expect(find.text('Not every required task fits'), findsNothing);
    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('schedule-shortage-notice')), findsNothing);
  });

  testWidgets('task edits preserve old plans and new plans can be selected', (
    tester,
  ) async {
    const task = DittoTask(
      name: 'Original scheduled task',
      minimumMinutes: 30,
      maximumMinutes: 30,
      importance: TaskImportance.canWait,
    );
    const block = AvailableTimeBlock(startMinutes: 9 * 60, endMinutes: 10 * 60);
    SharedPreferences.setMockInitialValues({
      'ditto.tasks.v1': jsonEncode([task.toJson()]),
      'ditto.available_time.v1': jsonEncode([block.toJson()]),
    });
    await tester.pumpWidget(const DittoApp());
    await tester.pumpAndSettle();

    await generatePlan(tester, 'Original plan');
    expect(find.text('Original scheduled task'), findsOneWidget);

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-task-0')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-name-field')),
      'Edited scheduled task',
    );
    final saveButton = find.byKey(const Key('save-task-button'));
    if (!tester.any(saveButton)) {
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();
    }
    tester.widget<FilledButton>(saveButton).onPressed!();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-time-block-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('increase-end-time')));
    await tester.tap(find.byKey(const Key('save-time-block-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(find.text('Original scheduled task'), findsOneWidget);
    expect(find.text('Edited scheduled task'), findsNothing);
    expect(find.byKey(const Key('outdated-plan-notice')), findsOneWidget);

    var preferences = await SharedPreferences.getInstance();
    var storedPlans =
        jsonDecode(preferences.getString('ditto.saved_plans.v1')!)
            as List<dynamic>;
    expect(storedPlans, hasLength(1));

    await generatePlan(tester, 'Edited plan');
    expect(find.text('Edited scheduled task'), findsOneWidget);
    expect(find.byKey(const Key('outdated-plan-notice')), findsNothing);

    preferences = await SharedPreferences.getInstance();
    storedPlans =
        jsonDecode(preferences.getString('ditto.saved_plans.v1')!)
            as List<dynamic>;
    expect(storedPlans, hasLength(2));

    await tester.tap(find.byKey(const Key('rename-saved-plan')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('plan-name-field')),
      'After-school plan',
    );
    await tester.tap(find.byKey(const Key('confirm-plan-name')));
    await tester.pumpAndSettle();
    expect(find.textContaining('After-school plan'), findsOneWidget);

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-task-0')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-name-field')),
      'Temporary unsaved setup',
    );
    if (!tester.any(saveButton)) {
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();
    }
    tester.widget<FilledButton>(saveButton).onPressed!();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('saved-plan-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Original plan').last);
    await tester.pumpAndSettle();
    expect(find.text('Save this changed setup?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('discard-plan-changes')));
    await tester.pumpAndSettle();
    expect(find.text('Original scheduled task'), findsOneWidget);
    expect(find.byKey(const Key('outdated-plan-notice')), findsNothing);

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    expect(find.text('Original scheduled task'), findsOneWidget);
    expect(find.text('Temporary unsaved setup'), findsNothing);
    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('edit-time-block-0')),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('9:00 AM – 10:00 AM'), findsOneWidget);
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('delete-saved-plan')));
    await tester.pumpAndSettle();
    expect(find.text('Delete this plan?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-delete-plan')));
    await tester.pumpAndSettle();
    expect(find.text('Edited scheduled task'), findsOneWidget);
    expect(find.byKey(const Key('outdated-plan-notice')), findsNothing);

    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('edit-time-block-0')),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('9:00 AM – 10:15 AM'), findsOneWidget);
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    preferences = await SharedPreferences.getInstance();
    storedPlans =
        jsonDecode(preferences.getString('ditto.saved_plans.v1')!)
            as List<dynamic>;
    expect(storedPlans, hasLength(1));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const DittoApp());
    await tester.pumpAndSettle();
    expect(find.text('Edited scheduled task'), findsOneWidget);
    expect(find.textContaining('After-school plan'), findsOneWidget);
    expect(find.text('New plan'), findsOneWidget);
  });
}
