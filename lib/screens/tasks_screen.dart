import 'package:flutter/material.dart';

import '../models/ditto_task.dart';
import '../widgets/screen_empty_state.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({
    required this.tasks,
    required this.onAddTask,
    required this.onEditTask,
    required this.onDeleteTask,
    super.key,
  });

  final List<DittoTask> tasks;
  final VoidCallback onAddTask;
  final ValueChanged<DittoTask> onEditTask;
  final ValueChanged<DittoTask> onDeleteTask;

  Future<void> _confirmDelete(BuildContext context, DittoTask task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('“${task.name}” will be removed from your task list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete ?? false) onDeleteTask(task);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          TextButton.icon(
            onPressed: onAddTask,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: tasks.isEmpty
            ? ScreenEmptyState(
                icon: Icons.checklist_rounded,
                title: 'No tasks yet',
                message:
                    'Tasks you add will be collected here so you can review them at a glance.',
                actionIcon: Icons.add_rounded,
                actionLabel: 'Add a task',
                onAction: onAddTask,
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: tasks.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return _TaskCard(
                    task: task,
                    index: index,
                    onEdit: () => onEditTask(task),
                    onDelete: () => _confirmDelete(context, task),
                  );
                },
              ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final DittoTask task;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(context, task.importance);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${_dueDateLabel(task.dueDate)} • '
                    '${_compactDuration(task.minimumMinutes)}–'
                    '${_compactDuration(task.maximumMinutes)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      task.importance.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: priorityColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: ValueKey('edit-task-$index'),
              tooltip: 'Edit ${task.name}',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              key: ValueKey('delete-task-$index'),
              tooltip: 'Delete ${task.name}',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

Color _priorityColor(BuildContext context, TaskImportance importance) {
  return switch (importance) {
    TaskImportance.mustComplete => Theme.of(context).colorScheme.error,
    TaskImportance.canWait => const Color(0xFF8A5A00),
    TaskImportance.optional => Theme.of(context).colorScheme.primary,
  };
}

String _dueDateLabel(DateTime? dueDate) {
  if (dueDate == null) return 'No deadline';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return 'Due ${months[dueDate.month - 1]} ${dueDate.day}';
}

String _compactDuration(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (remainingMinutes == 0) return '${hours}h';
  return '${hours}h ${remainingMinutes}m';
}
