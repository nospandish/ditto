import 'package:ditto/models/available_time_block.dart';
import 'package:ditto/models/ditto_task.dart';
import 'package:ditto/models/schedule_build_result.dart';
import 'package:ditto/models/scheduled_task.dart';
import 'package:ditto/screens/available_time_screen.dart';
import 'package:ditto/screens/tasks_screen.dart';
import 'package:ditto/screens/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const scheduledTask = DittoTask(
    name: 'Finish outline',
    minimumMinutes: 30,
    maximumMinutes: 30,
    importance: TaskImportance.mustComplete,
  );
  const unscheduledTask = DittoTask(
    name: 'Study vocabulary',
    minimumMinutes: 30,
    maximumMinutes: 30,
    importance: TaskImportance.mustComplete,
  );
  const optionalTask = DittoTask(
    name: 'Organize notes',
    minimumMinutes: 30,
    maximumMinutes: 30,
    importance: TaskImportance.optional,
  );

  testWidgets('explains an impossible plan and keeps the partial schedule', (
    tester,
  ) async {
    var reviewedTasks = false;
    var addedTime = false;
    final result = ScheduleBuildResult(
      scheduledTasks: const [
        ScheduledTask(
          task: scheduledTask,
          startMinutes: 9 * 60,
          endMinutes: 9 * 60 + 30,
        ),
      ],
      unscheduledTasks: const [unscheduledTask],
      issues: const [
        ScheduleIssue(
          task: unscheduledTask,
          reason: ScheduleIssueReason.insufficientTotalTime,
        ),
      ],
      totalAvailableMinutes: 45,
      mustCompleteMinimumMinutes: 60,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TodayScreen(
          hasTasks: true,
          hasAvailableTime: true,
          scheduleResult: result,
          currentMinutes: 8 * 60,
          onAddTask: () {},
          onAddAvailableTime: () => addedTime = true,
          onReviewTasks: () => reviewedTasks = true,
          onGeneratePlan: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('impossible-schedule-card')), findsOneWidget);
    expect(find.text('Not every required task fits'), findsOneWidget);
    expect(find.text('Study vocabulary'), findsOneWidget);
    expect(
      find.textContaining('Add 15 min or shorten a task.'),
      findsOneWidget,
    );
    expect(find.text('Best partial plan'), findsOneWidget);
    expect(find.text('Finish outline'), findsOneWidget);

    await tester.tap(find.byKey(const Key('review-conflicting-tasks-button')));
    expect(reviewedTasks, isTrue);

    await tester.tap(find.byKey(const Key('add-time-from-conflict-button')));
    expect(addedTime, isTrue);
  });

  testWidgets('explains fragmented availability without claiming a shortage', (
    tester,
  ) async {
    final result = ScheduleBuildResult(
      scheduledTasks: const [],
      unscheduledTasks: const [unscheduledTask],
      issues: const [
        ScheduleIssue(
          task: unscheduledTask,
          reason: ScheduleIssueReason.noContinuousWindow,
        ),
      ],
      totalAvailableMinutes: 60,
      mustCompleteMinimumMinutes: 30,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TodayScreen(
          hasTasks: true,
          hasAvailableTime: true,
          scheduleResult: result,
          currentMinutes: 8 * 60,
          onAddTask: () {},
          onAddAvailableTime: () {},
          onReviewTasks: () {},
          onGeneratePlan: () {},
        ),
      ),
    );

    expect(
      find.textContaining('available windows are too fragmented'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Needs a continuous 30 min block.'),
      findsOneWidget,
    );
    expect(find.textContaining('but only'), findsNothing);
    expect(
      find.text('No tasks could be placed in the available time yet.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a useful empty state when only optional work cannot fit', (
    tester,
  ) async {
    final result = ScheduleBuildResult(
      scheduledTasks: const [],
      unscheduledTasks: const [optionalTask],
      issues: const [],
      totalAvailableMinutes: 15,
      mustCompleteMinimumMinutes: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TodayScreen(
          hasTasks: true,
          hasAvailableTime: true,
          scheduleResult: result,
          onAddTask: () {},
          onAddAvailableTime: () {},
          onReviewTasks: () {},
          onGeneratePlan: () {},
        ),
      ),
    );

    expect(find.text('No tasks fit yet'), findsOneWidget);
    expect(find.text('Add available time'), findsOneWidget);
    expect(find.byKey(const Key('impossible-schedule-card')), findsNothing);
  });

  testWidgets('shows a summarized timeline for a successful plan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final result = ScheduleBuildResult(
      scheduledTasks: const [
        ScheduledTask(
          task: scheduledTask,
          startMinutes: 9 * 60,
          endMinutes: 9 * 60 + 30,
        ),
        ScheduledTask(
          task: optionalTask,
          startMinutes: 9 * 60 + 30,
          endMinutes: 10 * 60 + 15,
        ),
      ],
      unscheduledTasks: const [],
      issues: const [],
      totalAvailableMinutes: 75,
      mustCompleteMinimumMinutes: 30,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TodayScreen(
          hasTasks: true,
          hasAvailableTime: true,
          scheduleResult: result,
          currentMinutes: 8 * 60,
          onAddTask: () {},
          onAddAvailableTime: () {},
          onReviewTasks: () {},
          onGeneratePlan: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('schedule-timeline')), findsOneWidget);
    expect(find.text('Today\u2019s plan'), findsOneWidget);
    expect(find.text('2 tasks \u00b7 1h 15m planned'), findsOneWidget);
    expect(find.byKey(const Key('next-task-badge')), findsOneWidget);
    expect(find.text('9:00 AM'), findsOneWidget);
    expect(find.text('Finish outline'), findsOneWidget);
    expect(find.text('Organize notes'), findsOneWidget);
  });

  testWidgets('colors the current task blue and missed tasks red', (
    tester,
  ) async {
    final result = ScheduleBuildResult(
      scheduledTasks: const [
        ScheduledTask(
          task: scheduledTask,
          startMinutes: 9 * 60,
          endMinutes: 9 * 60 + 30,
        ),
        ScheduledTask(
          task: optionalTask,
          startMinutes: 9 * 60 + 30,
          endMinutes: 10 * 60 + 15,
        ),
      ],
      unscheduledTasks: const [],
      issues: const [],
      totalAvailableMinutes: 75,
      mustCompleteMinimumMinutes: 30,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TodayScreen(
          hasTasks: true,
          hasAvailableTime: true,
          scheduleResult: result,
          currentMinutes: 9 * 60 + 45,
          onAddTask: () {},
          onAddAvailableTime: () {},
          onReviewTasks: () {},
          onGeneratePlan: () {},
        ),
      ),
    );

    final previousCard = tester.widget<Card>(
      find.byKey(const ValueKey('schedule-task-Finish outline')),
    );
    final currentCard = tester.widget<Card>(
      find.byKey(const ValueKey('schedule-task-Organize notes')),
    );
    final currentShape = currentCard.shape! as RoundedRectangleBorder;

    expect(previousCard.color, const Color(0xFFA64B4B).withValues(alpha: 0.10));
    expect(currentCard.color, const Color(0xFF2563EB).withValues(alpha: 0.08));
    expect(currentShape.side.color, const Color(0xFF2563EB));
    expect(find.byKey(const Key('current-task-badge')), findsOneWidget);
    expect(find.text('Now'), findsOneWidget);
  });

  testWidgets('shows the shortage on the tasks page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TasksScreen(
          tasks: const [scheduledTask, unscheduledTask],
          minutesShort: 15,
          showScheduleWarning: true,
          onAddTask: () {},
          onEditTask: (_) {},
          onDeleteTask: (_) {},
        ),
      ),
    );

    expect(find.text('You\u2019re 15 min short.'), findsOneWidget);
  });

  testWidgets('shows how much time to add on the time page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AvailableTimeScreen(
          blocks: const [
            AvailableTimeBlock(startMinutes: 9 * 60, endMinutes: 9 * 60 + 45),
          ],
          scheduledTasks: const [],
          minutesShort: 15,
          showScheduleWarning: true,
          onAddBlock: () {},
          onEditBlock: (_) {},
          onDeleteBlock: (_) {},
        ),
      ),
    );

    expect(find.text('Add 15 min more.'), findsOneWidget);
  });
}
