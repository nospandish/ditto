import 'package:flutter/material.dart';

import '../models/scheduled_task.dart';
import '../widgets/screen_empty_state.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({
    required this.hasTasks,
    required this.hasAvailableTime,
    required this.schedule,
    required this.onAddTask,
    required this.onAddAvailableTime,
    required this.onGeneratePlan,
    super.key,
  });

  final bool hasTasks;
  final bool hasAvailableTime;
  final List<ScheduledTask> schedule;
  final VoidCallback onAddTask;
  final VoidCallback onAddAvailableTime;
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
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(schedule.isEmpty ? 'Generate' : 'Regenerate'),
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
    if (schedule.isEmpty) {
      return ScreenEmptyState(
        icon: Icons.auto_awesome_rounded,
        title: 'Ready to plan your day',
        message: 'Ditto will place your highest-priority tasks first.',
        actionIcon: Icons.auto_awesome_rounded,
        actionLabel: 'Generate plan',
        onAction: onGeneratePlan,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: schedule.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = schedule[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.check_circle_outline_rounded),
            title: Text(item.task.name),
            subtitle: Text(
              '${_formatTime(context, item.startMinutes)} – '
              '${_formatTime(context, item.endMinutes)} · '
              '${item.durationMinutes} min · ${item.task.importance.label}',
            ),
          ),
        );
      },
    );
  }
}

String _formatTime(BuildContext context, int minutes) {
  return MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));
}
