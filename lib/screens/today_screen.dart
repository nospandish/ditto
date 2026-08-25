import 'package:flutter/material.dart';

import '../models/schedule_build_result.dart';
import '../models/scheduled_task.dart';
import '../widgets/screen_empty_state.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({
    required this.hasTasks,
    required this.hasAvailableTime,
    required this.scheduleResult,
    required this.onAddTask,
    required this.onAddAvailableTime,
    required this.onReviewTasks,
    required this.onGeneratePlan,
    super.key,
  });

  final bool hasTasks;
  final bool hasAvailableTime;
  final ScheduleBuildResult? scheduleResult;
  final VoidCallback onAddTask;
  final VoidCallback onAddAvailableTime;
  final VoidCallback onReviewTasks;
  final VoidCallback onGeneratePlan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          if (hasTasks && hasAvailableTime)
            TextButton.icon(
              key: const Key('generate-plan-button'),
              onPressed: onGeneratePlan,
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(scheduleResult == null ? 'Generate' : 'Regenerate'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (!hasTasks) {
      return ScreenEmptyState(
        icon: Icons.calendar_today_rounded,
        title: 'Make today manageable.',
        message: 'Add tasks, then Ditto can build a simple plan for your day.',
        actionIcon: Icons.add_task_rounded,
        actionLabel: 'Add your first task',
        onAction: onAddTask,
      );
    }
    if (!hasAvailableTime) {
      return ScreenEmptyState(
        icon: Icons.schedule_rounded,
        title: 'When are you free?',
        message: 'Add an available-time window before generating your plan.',
        actionIcon: Icons.add_rounded,
        actionLabel: 'Add available time',
        onAction: onAddAvailableTime,
      );
    }
    if (scheduleResult == null) {
      return ScreenEmptyState(
        icon: Icons.auto_awesome_rounded,
        title: 'Ready to plan your day',
        message: 'Ditto will place your highest-priority tasks first.',
        actionIcon: Icons.auto_awesome_rounded,
        actionLabel: 'Generate plan',
        onAction: onGeneratePlan,
      );
    }

    final result = scheduleResult!;
    if (result.hasImpossibleMustCompleteTasks) {
      return _ImpossibleScheduleView(
        result: result,
        onReviewTasks: onReviewTasks,
        onAddAvailableTime: onAddAvailableTime,
      );
    }
    if (result.scheduledTasks.isEmpty) {
      return ScreenEmptyState(
        icon: Icons.event_busy_rounded,
        title: 'No tasks fit yet',
        message:
            'Try adding a longer available-time window or shortening a task.',
        actionIcon: Icons.more_time_rounded,
        actionLabel: 'Add available time',
        onAction: onAddAvailableTime,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: result.scheduledTasks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _ScheduleCard(item: result.scheduledTasks[index]),
    );
  }
}

class _ImpossibleScheduleView extends StatelessWidget {
  const _ImpossibleScheduleView({
    required this.result,
    required this.onReviewTasks,
    required this.onAddAvailableTime,
  });

  final ScheduleBuildResult result;
  final VoidCallback onReviewTasks;
  final VoidCallback onAddAvailableTime;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _ImpossibleScheduleCard(
          result: result,
          onReviewTasks: onReviewTasks,
          onAddAvailableTime: onAddAvailableTime,
        ),
        const SizedBox(height: 20),
        Text(
          'Best partial plan',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          result.scheduledTasks.isEmpty
              ? 'No tasks could be placed in the available time yet.'
              : 'These tasks still fit without breaking your availability.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (result.scheduledTasks.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (
            var index = 0;
            index < result.scheduledTasks.length;
            index++
          ) ...[
            _ScheduleCard(item: result.scheduledTasks[index]),
            if (index != result.scheduledTasks.length - 1)
              const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _ImpossibleScheduleCard extends StatelessWidget {
  const _ImpossibleScheduleCard({
    required this.result,
    required this.onReviewTasks,
    required this.onAddAvailableTime,
  });

  final ScheduleBuildResult result;
  final VoidCallback onReviewTasks;
  final VoidCallback onAddAvailableTime;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      key: const Key('impossible-schedule-card'),
      margin: EdgeInsets.zero,
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Not every required task fits',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _resultExplanation(result),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 14),
            for (final issue in result.issues)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 20,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            issue.task.name,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(color: colorScheme.onErrorContainer),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _issueExplanation(issue, result),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onErrorContainer),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('review-conflicting-tasks-button'),
                  onPressed: onReviewTasks,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Review tasks'),
                ),
                FilledButton.icon(
                  key: const Key('add-time-from-conflict-button'),
                  onPressed: onAddAvailableTime,
                  icon: const Icon(Icons.more_time_rounded),
                  label: const Text('Add time'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.item});

  final ScheduledTask item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline_rounded),
        title: Text(item.task.name),
        subtitle: Text(
          '${_formatTime(context, item.startMinutes)} - '
          '${_formatTime(context, item.endMinutes)} \u00b7 '
          '${item.durationMinutes} min \u00b7 ${item.task.importance.label}',
        ),
      ),
    );
  }
}

String _resultExplanation(ScheduleBuildResult result) {
  if (result.issues.any(
    (issue) => issue.reason == ScheduleIssueReason.noAvailableTime,
  )) {
    return 'Add available time before trying to place the required work.';
  }
  if (result.minutesShort > 0) {
    return 'Required tasks need at least '
        '${_formatDuration(result.mustCompleteMinimumMinutes)}, but only '
        '${_formatDuration(result.totalAvailableMinutes)} is available. Add '
        '${_formatDuration(result.minutesShort)} or shorten a task.';
  }
  return 'There is enough time overall, but the available windows are too '
      'fragmented. Add a longer continuous block or shorten a task.';
}

String _issueExplanation(ScheduleIssue issue, ScheduleBuildResult result) {
  return switch (issue.reason) {
    ScheduleIssueReason.noAvailableTime =>
      'Needs at least ${_formatDuration(issue.task.minimumMinutes)}.',
    ScheduleIssueReason.insufficientTotalTime =>
      'Could not fit because the required plan is '
          '${_formatDuration(result.minutesShort)} short.',
    ScheduleIssueReason.noContinuousWindow =>
      'Needs a continuous ${_formatDuration(issue.task.minimumMinutes)} block.',
  };
}

String _formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (hours == 0) return '$remainingMinutes min';
  if (remainingMinutes == 0) return '${hours}h';
  return '${hours}h ${remainingMinutes}m';
}

String _formatTime(BuildContext context, int minutes) {
  return MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));
}
