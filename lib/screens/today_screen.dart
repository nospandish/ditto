import 'package:flutter/material.dart';

import '../models/saved_plan.dart';
import '../models/ditto_task.dart';
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
    this.savedPlans = const [],
    this.activePlan,
    this.isActivePlanOutdated = false,
    this.onSelectPlan,
    this.onRenamePlan,
    this.onDeletePlan,
    this.onUpdateTaskStatus,
    this.currentMinutes,
    super.key,
  });

  final bool hasTasks;
  final bool hasAvailableTime;
  final ScheduleBuildResult? scheduleResult;
  final VoidCallback onAddTask;
  final VoidCallback onAddAvailableTime;
  final VoidCallback onReviewTasks;
  final VoidCallback onGeneratePlan;
  final List<SavedPlan> savedPlans;
  final SavedPlan? activePlan;
  final bool isActivePlanOutdated;
  final ValueChanged<String>? onSelectPlan;
  final ValueChanged<SavedPlan>? onRenamePlan;
  final ValueChanged<SavedPlan>? onDeletePlan;
  final void Function(ScheduledTask task, ScheduledTaskStatus status)?
  onUpdateTaskStatus;
  final int? currentMinutes;

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
              label: Text(savedPlans.isEmpty ? 'Generate' : 'New plan'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    if (scheduleResult != null && activePlan != null) {
      return Column(
        children: [
          _SavedPlanHeader(
            plans: savedPlans,
            activePlan: activePlan!,
            onSelectPlan: onSelectPlan,
            onRenamePlan: onRenamePlan,
            onDeletePlan: onDeletePlan,
          ),
          if (isActivePlanOutdated) const _OutdatedPlanNotice(),
          Expanded(child: _scheduleBody()),
        ],
      );
    }
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

    return _scheduleBody();
  }

  Widget _scheduleBody() {
    final result = scheduleResult!;
    if (result.hasImpossibleMustCompleteTasks) {
      return _ImpossibleScheduleView(
        result: result,
        currentMinutes: currentMinutes ?? _minutesNow(),
        onReviewTasks: onReviewTasks,
        onAddAvailableTime: onAddAvailableTime,
        onUpdateTaskStatus: onUpdateTaskStatus,
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

    return _ScheduleTimeline(
      items: result.scheduledTasks,
      showSummary: true,
      showNextBadge: true,
      currentMinutes: currentMinutes ?? _minutesNow(),
      onUpdateTaskStatus: onUpdateTaskStatus,
    );
  }
}

class _SavedPlanHeader extends StatelessWidget {
  const _SavedPlanHeader({
    required this.plans,
    required this.activePlan,
    required this.onSelectPlan,
    required this.onRenamePlan,
    required this.onDeletePlan,
  });

  final List<SavedPlan> plans;
  final SavedPlan activePlan;
  final ValueChanged<String>? onSelectPlan;
  final ValueChanged<SavedPlan>? onRenamePlan;
  final ValueChanged<SavedPlan>? onDeletePlan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Saved plan',
                prefixIcon: Icon(Icons.bookmarks_outlined),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: const Key('saved-plan-picker'),
                  value: activePlan.id,
                  isExpanded: true,
                  isDense: true,
                  items: [
                    for (final plan in plans)
                      DropdownMenuItem(
                        value: plan.id,
                        child: Text(
                          _planLabel(context, plan),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: onSelectPlan == null
                      ? null
                      : (value) {
                          if (value != null) onSelectPlan!(value);
                        },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            key: const Key('rename-saved-plan'),
            tooltip: 'Rename selected plan',
            onPressed: onRenamePlan == null
                ? null
                : () => onRenamePlan!(activePlan),
            icon: const Icon(Icons.edit_outlined),
          ),
          const SizedBox(width: 4),
          IconButton.filledTonal(
            key: const Key('delete-saved-plan'),
            tooltip: 'Delete selected plan',
            onPressed: onDeletePlan == null
                ? null
                : () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this plan?'),
        content: const Text(
          'Its saved tasks and scheduled times will be removed. If another '
          'plan remains, Ditto will load it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-delete-plan'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete plan'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) onDeletePlan?.call(activePlan);
  }
}

class _OutdatedPlanNotice extends StatelessWidget {
  const _OutdatedPlanNotice();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('outdated-plan-notice'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: colorScheme.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This plan uses earlier task or available-time details.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _planLabel(BuildContext context, SavedPlan plan) {
  final localizations = MaterialLocalizations.of(context);
  final date = localizations.formatShortDate(plan.createdAt);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(plan.createdAt),
  );
  return '${plan.name} · $date, $time';
}

class _ImpossibleScheduleView extends StatelessWidget {
  const _ImpossibleScheduleView({
    required this.result,
    required this.currentMinutes,
    required this.onReviewTasks,
    required this.onAddAvailableTime,
    this.onUpdateTaskStatus,
  });

  final ScheduleBuildResult result;
  final int currentMinutes;
  final VoidCallback onReviewTasks;
  final VoidCallback onAddAvailableTime;
  final void Function(ScheduledTask task, ScheduledTaskStatus status)?
  onUpdateTaskStatus;

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
          _ScheduleTimeline(
            items: result.scheduledTasks,
            showSummary: false,
            showNextBadge: false,
            currentMinutes: currentMinutes,
            shrinkWrap: true,
            onUpdateTaskStatus: onUpdateTaskStatus,
          ),
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
                FilledButton.icon(
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

class _ScheduleTimeline extends StatelessWidget {
  const _ScheduleTimeline({
    required this.items,
    required this.showSummary,
    required this.showNextBadge,
    required this.currentMinutes,
    this.onUpdateTaskStatus,
    this.shrinkWrap = false,
  });

  final List<ScheduledTask> items;
  final bool showSummary;
  final bool showNextBadge;
  final int currentMinutes;
  final void Function(ScheduledTask task, ScheduledTaskStatus status)?
  onUpdateTaskStatus;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final totalMinutes = items.fold<int>(
      0,
      (total, item) => total + item.durationMinutes,
    );

    final states = items
        .map((item) => _timelineState(item, currentMinutes))
        .toList(growable: false);
    final currentIndex = states.indexOf(_TimelineTaskState.current);
    final nextIndex = currentIndex == -1
        ? states.indexOf(_TimelineTaskState.upcoming)
        : -1;

    final children = <Widget>[
      if (showSummary) ...[
        _ScheduleSummary(taskCount: items.length, totalMinutes: totalMinutes),
        const SizedBox(height: 18),
      ],
      for (var index = 0; index < items.length; index++)
        _TimelineItem(
          item: items[index],
          isFirst: index == 0,
          isLast: index == items.length - 1,
          state: states[index],
          badgeLabel:
              !showNextBadge ||
                  items[index].status != ScheduledTaskStatus.planned
              ? null
              : index == currentIndex
              ? 'Now'
              : index == nextIndex
              ? 'Next'
              : null,
          onUpdateTaskStatus: onUpdateTaskStatus,
        ),
    ];

    if (shrinkWrap) {
      return Column(children: children);
    }

    return ListView(
      key: const Key('schedule-timeline'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: children,
    );
  }
}

class _ScheduleSummary extends StatelessWidget {
  const _ScheduleSummary({required this.taskCount, required this.totalMinutes});

  final int taskCount;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: const Key('schedule-summary'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.today_rounded, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\u2019s plan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$taskCount ${taskCount == 1 ? 'task' : 'tasks'} \u00b7 '
                  '${_formatDuration(totalMinutes)} planned',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.item,
    required this.isFirst,
    required this.isLast,
    required this.state,
    required this.badgeLabel,
    this.onUpdateTaskStatus,
  });

  final ScheduledTask item;
  final bool isFirst;
  final bool isLast;
  final _TimelineTaskState state;
  final String? badgeLabel;
  final void Function(ScheduledTask task, ScheduledTaskStatus status)?
  onUpdateTaskStatus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final priorityColor = switch (item.task.importance) {
      TaskImportance.mustComplete => colorScheme.error,
      TaskImportance.canWait => const Color(0xFF9A6700),
      TaskImportance.optional => colorScheme.primary,
    };
    const currentColor = Color(0xFF2563EB);
    final stateColor = switch (state) {
      _TimelineTaskState.previous => colorScheme.outline,
      _TimelineTaskState.current => currentColor,
      _TimelineTaskState.upcoming => priorityColor,
    };
    final cardColor = switch (state) {
      _TimelineTaskState.previous => colorScheme.surfaceContainerHighest,
      _TimelineTaskState.current => currentColor.withValues(alpha: 0.08),
      _TimelineTaskState.upcoming => null,
    };
    final titleColor = state == _TimelineTaskState.previous
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurface;
    final isCompleted = item.status == ScheduledTaskStatus.completed;
    final isSkipped = item.status == ScheduledTaskStatus.skipped;
    final isResolved = isCompleted || isSkipped;
    final effectiveTitleColor = isResolved
        ? colorScheme.onSurfaceVariant
        : titleColor;
    final effectiveStateColor = isResolved ? colorScheme.outline : stateColor;
    final effectiveCardColor = isResolved
        ? colorScheme.surfaceContainerHighest
        : cardColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 13),
                Text(
                  _formatTime(context, item.startMinutes),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatTime(context, item.endMinutes),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 18,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isFirst)
                  Positioned(
                    top: 0,
                    height: 17,
                    child: Container(
                      width: 2,
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                if (!isLast)
                  Positioned(
                    top: 17,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                Positioned(
                  top: 12,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: effectiveStateColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                key: ValueKey('schedule-task-${item.task.name}'),
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: state == _TimelineTaskState.current && !isResolved
                      ? const BorderSide(color: currentColor, width: 1.5)
                      : BorderSide.none,
                ),
                color: effectiveCardColor,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.task.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: effectiveTitleColor,
                                    fontWeight: FontWeight.w700,
                                    decoration: isResolved
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                            ),
                          ),
                          if (badgeLabel != null)
                            Container(
                              key: ValueKey(
                                badgeLabel == 'Now'
                                    ? 'current-task-badge'
                                    : 'next-task-badge',
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: effectiveStateColor.withValues(
                                  alpha: 0.14,
                                ),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                badgeLabel!,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: effectiveStateColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _TaskDetailChip(
                            icon: Icons.timer_outlined,
                            label: _formatDuration(item.durationMinutes),
                          ),
                          _TaskDetailChip(
                            label: item.task.importance.label,
                            color:
                                isResolved ||
                                    state == _TimelineTaskState.previous
                                ? colorScheme.outline
                                : priorityColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isResolved)
                        Row(
                          children: [
                            Icon(
                              isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.skip_next_rounded,
                              size: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isCompleted ? 'Completed' : 'Skipped',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const Spacer(),
                            if (onUpdateTaskStatus != null)
                              PopupMenuButton<ScheduledTaskStatus>(
                                key: ValueKey(
                                  'status-menu-schedule-task-${item.task.name}',
                                ),
                                tooltip: 'Change task status',
                                onSelected: (status) {
                                  onUpdateTaskStatus!(item, status);
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    key: ValueKey(
                                      'undo-schedule-task-${item.task.name}',
                                    ),
                                    value: ScheduledTaskStatus.planned,
                                    child: const Text('Undo status'),
                                  ),
                                ],
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Change'),
                                      Icon(Icons.arrow_drop_down_rounded),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        )
                      else if (onUpdateTaskStatus != null)
                        PopupMenuButton<ScheduledTaskStatus>(
                          key: ValueKey(
                            'status-menu-schedule-task-${item.task.name}',
                          ),
                          tooltip: 'Update task status',
                          onSelected: (status) {
                            if (status == ScheduledTaskStatus.skipped) {
                              _confirmSkip(context);
                            } else {
                              onUpdateTaskStatus!(item, status);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              key: ValueKey(
                                'status-option-done-${item.task.name}',
                              ),
                              value: ScheduledTaskStatus.completed,
                              child: const Text('Mark as done'),
                            ),
                            PopupMenuItem(
                              key: ValueKey(
                                'status-option-skip-${item.task.name}',
                              ),
                              value: ScheduledTaskStatus.skipped,
                              child: const Text('Skip task'),
                            ),
                          ],
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(color: colorScheme.outline),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Update status',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_drop_down_rounded,
                                    color: colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSkip(BuildContext context) async {
    final shouldSkip = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip this task?'),
        content: const Text(
          'It will stay visible in this plan but will not count as completed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-skip-schedule-task'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Skip task'),
          ),
        ],
      ),
    );
    if (shouldSkip == true && context.mounted) {
      onUpdateTaskStatus?.call(item, ScheduledTaskStatus.skipped);
    }
  }
}

class _TaskDetailChip extends StatelessWidget {
  const _TaskDetailChip({required this.label, this.icon, this.color});

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum _TimelineTaskState { previous, current, upcoming }

_TimelineTaskState _timelineState(ScheduledTask item, int currentMinutes) {
  if (item.endMinutes <= currentMinutes) return _TimelineTaskState.previous;
  if (item.startMinutes <= currentMinutes) return _TimelineTaskState.current;
  return _TimelineTaskState.upcoming;
}

int _minutesNow() {
  final now = DateTime.now();
  return now.hour * 60 + now.minute;
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
