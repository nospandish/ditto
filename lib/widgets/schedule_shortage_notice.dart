import 'package:flutter/material.dart';

class ScheduleShortageNotice extends StatelessWidget {
  const ScheduleShortageNotice({
    required this.minutesShort,
    required this.message,
    required this.resolvedMessage,
    super.key,
  });

  final int minutesShort;
  final String Function(String duration) message;
  final String resolvedMessage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      key: const Key('schedule-shortage-notice'),
      margin: EdgeInsets.zero,
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                minutesShort > 0
                    ? message(_formatDuration(minutesShort))
                    : resolvedMessage,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
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
