import 'package:flutter/material.dart';

import '../models/available_time_block.dart';
import '../models/scheduled_task.dart';
import '../widgets/available_time_clock.dart';
import '../widgets/schedule_shortage_notice.dart';
import '../widgets/screen_empty_state.dart';

class AvailableTimeScreen extends StatelessWidget {
  const AvailableTimeScreen({
    required this.blocks,
    required this.scheduledTasks,
    required this.onAddBlock,
    required this.onEditBlock,
    required this.onDeleteBlock,
    this.minutesShort = 0,
    this.showScheduleWarning = false,
    super.key,
  });

  final List<AvailableTimeBlock> blocks;
  final List<ScheduledTask> scheduledTasks;
  final VoidCallback onAddBlock;
  final ValueChanged<AvailableTimeBlock> onEditBlock;
  final ValueChanged<AvailableTimeBlock> onDeleteBlock;
  final int minutesShort;
  final bool showScheduleWarning;

  Future<void> _confirmDelete(
    BuildContext context,
    AvailableTimeBlock block,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete available time?'),
        content: const Text(
          'This window will no longer be available for scheduling tasks.',
        ),
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

    if (shouldDelete ?? false) onDeleteBlock(block);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Time'),
        actions: [
          TextButton.icon(
            onPressed: onAddBlock,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: blocks.isEmpty
            ? ScreenEmptyState(
                icon: Icons.schedule_rounded,
                title: 'When are you free?',
                message:
                    'Your available time windows will appear here once you add them.',
                actionIcon: Icons.add_rounded,
                actionLabel: 'Add available time',
                onAction: onAddBlock,
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (showScheduleWarning) ...[
                    ScheduleShortageNotice(
                      minutesShort: minutesShort,
                      message: (duration) => 'Add $duration more.',
                      resolvedMessage:
                          'Your changes may fit. Regenerate to confirm.',
                    ),
                    const SizedBox(height: 16),
                  ],
                  AvailableTimeClock(
                    blocks: blocks,
                    scheduledTasks: scheduledTasks,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Today’s windows',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 10),
                  for (var index = 0; index < blocks.length; index++) ...[
                    _AvailableTimeCard(
                      block: blocks[index],
                      index: index,
                      onEdit: () => onEditBlock(blocks[index]),
                      onDelete: () => _confirmDelete(context, blocks[index]),
                    ),
                    if (index != blocks.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
      ),
    );
  }
}

class _AvailableTimeCard extends StatelessWidget {
  const _AvailableTimeCard({
    required this.block,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final AvailableTimeBlock block;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final start = localizations.formatTimeOfDay(
      _asTimeOfDay(block.startMinutes),
    );
    final end = localizations.formatTimeOfDay(_asTimeOfDay(block.endMinutes));

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.access_time_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$start – $end',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDuration(block.durationMinutes),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: ValueKey('edit-time-block-$index'),
              tooltip: 'Edit available-time window',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              key: ValueKey('delete-time-block-$index'),
              tooltip: 'Delete available-time window',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (hours == 0) return '$remainingMinutes min';
  if (remainingMinutes == 0) return '${hours}h';
  return '${hours}h ${remainingMinutes}m';
}

TimeOfDay _asTimeOfDay(int minutes) {
  return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
}
