import 'package:ditto/app/app.dart';
import 'package:ditto/screens/add_task_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> openAddTaskScreen(WidgetTester tester) async {
    await tester.pumpWidget(const DittoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a task'));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    if (!tester.any(finder)) {
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();
    }
    final button = tester.widget<FilledButton>(finder);
    button.onPressed!();
    await tester.pumpAndSettle();
  }

  testWidgets('adds, edits, and deletes a task', (tester) async {
    await openAddTaskScreen(tester);

    expect(find.text('Add Task'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('task-name-field')),
      'Finish history outline',
    );
    await tester.tap(find.byKey(const Key('importance-canWait')));
    await tapVisible(tester, find.byKey(const Key('save-task-button')));

    expect(find.text('Finish history outline'), findsOneWidget);
    expect(find.text('No deadline • 30m–1h'), findsOneWidget);
    expect(find.text('Can wait'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('edit-task-0')));
    await tester.pumpAndSettle();
    expect(find.text('Edit Task'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('task-name-field')),
      'Finish revised history outline',
    );
    await tapVisible(tester, find.byKey(const Key('save-task-button')));

    expect(find.text('Finish revised history outline'), findsOneWidget);
    expect(find.text('Finish history outline'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('delete-task-0')));
    await tester.pumpAndSettle();
    expect(find.text('Delete task?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('No tasks yet'), findsOneWidget);
  });

  testWidgets('requires a task name', (tester) async {
    await openAddTaskScreen(tester);

    await tapVisible(tester, find.byKey(const Key('save-task-button')));

    expect(find.text('Enter a task name.'), findsOneWidget);
    expect(find.text('Add Task'), findsOneWidget);
  });

  testWidgets('requires maximum time to be at least minimum time', (
    tester,
  ) async {
    await openAddTaskScreen(tester);
    await tester.enterText(
      find.byKey(const Key('task-name-field')),
      'Short task',
    );

    final increaseMinimum = find.byKey(const Key('increase-minimum-duration'));
    await tester.ensureVisible(increaseMinimum);
    for (var i = 0; i < 3; i++) {
      tester.widget<IconButton>(increaseMinimum).onPressed!();
      await tester.pump();
    }
    final saveButton = find.byKey(const Key('save-task-button'));
    tester.widget<FilledButton>(saveButton).onPressed!();
    await tester.pumpAndSettle();

    expect(
      find.text('Maximum time must be at least the minimum time.'),
      findsOneWidget,
    );
    expect(find.text('Add Task'), findsOneWidget);
  });

  testWidgets('accepts typed duration ranges', (tester) async {
    await openAddTaskScreen(tester);
    await tester.enterText(
      find.byKey(const Key('task-name-field')),
      'Typed duration task',
    );
    await tester.enterText(
      find.byKey(const ValueKey('minimum-duration-field')),
      '1h 30m',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.enterText(
      find.byKey(const ValueKey('maximum-duration-field')),
      '2h',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tapVisible(tester, find.byKey(const Key('save-task-button')));

    expect(find.text('No deadline • 1h 30m–2h'), findsOneWidget);
  });

  testWidgets('updates both duration values with the range slider', (
    tester,
  ) async {
    await openAddTaskScreen(tester);
    final slider = tester.widget<RangeSlider>(
      find.byKey(const Key('duration-range-slider')),
    );
    slider.onChanged!(const RangeValues(60, 180));
    await tester.pump();

    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('minimum-duration-field')),
          )
          .controller!
          .text,
      '60',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('maximum-duration-field')),
          )
          .controller!
          .text,
      '180',
    );
  });

  testWidgets('offers common task names in a dropdown', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddTaskScreen(commonTaskNames: const ['Homework', 'Read a book']),
      ),
    );
    await tester.tap(find.byKey(const Key('common-task-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Homework').last);

    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('task-name-field')))
          .controller!
          .text,
      'Homework',
    );
  });
}
