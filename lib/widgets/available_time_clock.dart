import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/available_time_block.dart';
import '../models/scheduled_task.dart';

const double _startOfDayAngle = math.pi / 2;
const List<Color> _scheduledTaskColors = [
  Color(0xFFFFD166),
  Color(0xFF70D6FF),
  Color(0xFFFFB3C7),
  Color(0xFFCDB4DB),
  Color(0xFFFFB59A),
];

@visibleForTesting
double availableTimeAngleForMinutes(int minutes) {
  return _startOfDayAngle + (minutes / Duration.minutesPerDay) * 2 * math.pi;
}

class AvailableTimeClock extends StatelessWidget {
  const AvailableTimeClock({
    required this.blocks,
    this.scheduledTasks = const [],
    super.key,
  });

  final List<AvailableTimeBlock> blocks;
  final List<ScheduledTask> scheduledTasks;

  int get _totalMinutes =>
      blocks.fold(0, (total, block) => total + block.durationMinutes);

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final sortedBlocks = [...blocks]
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    final sortedScheduledTasks = [...scheduledTasks]
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    final semanticsLabel = _buildSemanticsLabel(
      blocks: sortedBlocks,
      scheduledTasks: sortedScheduledTasks,
      localizations: localizations,
      totalMinutes: _totalMinutes,
    );

    return Semantics(
      key: const Key('available-time-clock'),
      container: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              SizedBox.square(
                dimension: 288,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        size: const Size.square(288),
                        painter: _AvailableTimeClockPainter(
                          blocks: sortedBlocks,
                          scheduledTasks: sortedScheduledTasks,
                          availableColor: Theme.of(context).colorScheme.primary,
                          scheduledSeparatorColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          unavailableColor: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.72),
                          tickColor: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const _ClockMarker(
                      key: Key('midnight-marker'),
                      label: '12 AM',
                      icon: Icons.dark_mode_rounded,
                      iconColor: Color(0xFF53657A),
                      alignment: Alignment.bottomCenter,
                      axis: Axis.horizontal,
                    ),
                    const _ClockMarker(
                      key: Key('sunrise-marker'),
                      label: '6 AM',
                      icon: Icons.wb_twilight_rounded,
                      iconColor: Color(0xFFD99A25),
                      alignment: Alignment.centerLeft,
                      axis: Axis.vertical,
                    ),
                    const _ClockMarker(
                      key: Key('noon-marker'),
                      label: '12 PM',
                      icon: Icons.light_mode_rounded,
                      iconColor: Color(0xFFE1A11D),
                      alignment: Alignment.topCenter,
                      axis: Axis.horizontal,
                    ),
                    const _ClockMarker(
                      key: Key('sunset-marker'),
                      label: '6 PM',
                      icon: Icons.wb_twilight_rounded,
                      iconColor: Color(0xFFC96F45),
                      alignment: Alignment.centerRight,
                      axis: Axis.vertical,
                    ),
                    _ClockCenter(totalMinutes: _totalMinutes),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _ClockLegend(
                scheduledTasks: sortedScheduledTasks,
                localizations: localizations,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailableTimeClockPainter extends CustomPainter {
  _AvailableTimeClockPainter({
    required List<AvailableTimeBlock> blocks,
    required List<ScheduledTask> scheduledTasks,
    required this.availableColor,
    required this.scheduledSeparatorColor,
    required this.unavailableColor,
    required this.tickColor,
  }) : blocks = List.unmodifiable(blocks),
       scheduledTasks = List.unmodifiable(scheduledTasks);

  final List<AvailableTimeBlock> blocks;
  final List<ScheduledTask> scheduledTasks;
  final Color availableColor;
  final Color scheduledSeparatorColor;
  final Color unavailableColor;
  final Color tickColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 64;
    const strokeWidth = 20.0;
    final ringBounds = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = unavailableColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    final availablePaint = Paint()
      ..color = availableColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    for (final block in blocks) {
      final startAngle = availableTimeAngleForMinutes(block.startMinutes);
      final sweepAngle =
          (block.durationMinutes / Duration.minutesPerDay) * 2 * math.pi;
      canvas.drawArc(ringBounds, startAngle, sweepAngle, false, availablePaint);
    }

    for (var index = 0; index < scheduledTasks.length; index++) {
      final item = scheduledTasks[index];
      final separatorPaint = Paint()
        ..color = scheduledSeparatorColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = 12;
      final scheduledPaint = Paint()
        ..color = _scheduledTaskColors[index % _scheduledTaskColors.length]
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = 7;
      final startAngle = availableTimeAngleForMinutes(item.startMinutes);
      final sweepAngle =
          (item.durationMinutes / Duration.minutesPerDay) * 2 * math.pi;
      canvas.drawArc(ringBounds, startAngle, sweepAngle, false, separatorPaint);
      canvas.drawArc(ringBounds, startAngle, sweepAngle, false, scheduledPaint);
    }

    final tickPaint = Paint()
      ..color = tickColor.withValues(alpha: 0.38)
      ..strokeCap = StrokeCap.round;

    for (var hour = 0; hour < 24; hour++) {
      final angle = availableTimeAngleForMinutes(
        hour * Duration.minutesPerHour,
      );
      final isMajorTick = hour % 6 == 0;
      final innerRadius = radius + strokeWidth / 2 + 4;
      final outerRadius = innerRadius + (isMajorTick ? 8 : 4);
      tickPaint.strokeWidth = isMajorTick ? 2 : 1;
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * innerRadius,
        center + Offset(math.cos(angle), math.sin(angle)) * outerRadius,
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AvailableTimeClockPainter oldDelegate) {
    if (availableColor != oldDelegate.availableColor ||
        scheduledSeparatorColor != oldDelegate.scheduledSeparatorColor ||
        unavailableColor != oldDelegate.unavailableColor ||
        tickColor != oldDelegate.tickColor ||
        blocks.length != oldDelegate.blocks.length ||
        scheduledTasks.length != oldDelegate.scheduledTasks.length) {
      return true;
    }

    for (var index = 0; index < blocks.length; index++) {
      final block = blocks[index];
      final oldBlock = oldDelegate.blocks[index];
      if (block.startMinutes != oldBlock.startMinutes ||
          block.endMinutes != oldBlock.endMinutes) {
        return true;
      }
    }
    for (var index = 0; index < scheduledTasks.length; index++) {
      final item = scheduledTasks[index];
      final oldItem = oldDelegate.scheduledTasks[index];
      if (item.startMinutes != oldItem.startMinutes ||
          item.endMinutes != oldItem.endMinutes) {
        return true;
      }
    }
    return false;
  }
}

class _ClockMarker extends StatelessWidget {
  const _ClockMarker({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.alignment,
    required this.axis,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Alignment alignment;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final markerChildren = <Widget>[
      Icon(icon, color: iconColor, size: 48),
      SizedBox(width: axis == Axis.horizontal ? 4 : 0, height: 2),
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    ];

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: axis == Axis.horizontal
                ? Row(mainAxisSize: MainAxisSize.min, children: markerChildren)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: markerChildren,
                  ),
          ),
        ),
      ),
    );
  }
}

class _ClockCenter extends StatelessWidget {
  const _ClockCenter({required this.totalMinutes});

  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 126,
      height: 126,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule_rounded, color: colorScheme.primary, size: 24),
          const SizedBox(height: 5),
          Text(
            _formatDuration(totalMinutes),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'available today',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockLegend extends StatelessWidget {
  const _ClockLegend({
    required this.scheduledTasks,
    required this.localizations,
  });

  final List<ScheduledTask> scheduledTasks;
  final MaterialLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 18,
          runSpacing: 8,
          children: [
            _LegendItem(color: colorScheme.primary, label: 'Available'),
            _LegendItem(
              color: colorScheme.surface.withValues(alpha: 0.72),
              label: 'Unavailable',
            ),
          ],
        ),
        if (scheduledTasks.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Scheduled tasks',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < scheduledTasks.length; index++)
                _ScheduledTaskLegendItem(
                  key: ValueKey('scheduled-task-legend-$index'),
                  item: scheduledTasks[index],
                  color:
                      _scheduledTaskColors[index % _scheduledTaskColors.length],
                  localizations: localizations,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ScheduledTaskLegendItem extends StatelessWidget {
  const _ScheduledTaskLegendItem({
    required this.item,
    required this.color,
    required this.localizations,
    super.key,
  });

  final ScheduledTask item;
  final Color color;
  final MaterialLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final start = localizations.formatTimeOfDay(
      _asTimeOfDay(item.startMinutes),
    );
    final end = localizations.formatTimeOfDay(_asTimeOfDay(item.endMinutes));

    return Container(
      constraints: const BoxConstraints(maxWidth: 248),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.onPrimaryContainer,
                width: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              '${item.task.name} · $start–$end',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

String _buildSemanticsLabel({
  required List<AvailableTimeBlock> blocks,
  required List<ScheduledTask> scheduledTasks,
  required MaterialLocalizations localizations,
  required int totalMinutes,
}) {
  final buffer = StringBuffer(
    'Available time clock. Noon and sun are at the top, sunset is at 6 PM '
    'on the right, midnight and moon are at the bottom, and sunrise is at '
    '6 AM on the left. ${_formatDuration(totalMinutes)} available today.',
  );
  for (final block in blocks) {
    final start = localizations.formatTimeOfDay(
      _asTimeOfDay(block.startMinutes),
    );
    final end = localizations.formatTimeOfDay(_asTimeOfDay(block.endMinutes));
    buffer.write(' Available from $start to $end.');
  }
  for (final item in scheduledTasks) {
    final start = localizations.formatTimeOfDay(
      _asTimeOfDay(item.startMinutes),
    );
    final end = localizations.formatTimeOfDay(_asTimeOfDay(item.endMinutes));
    buffer.write(' Scheduled task ${item.task.name} from $start to $end.');
  }
  return buffer.toString();
}

String _formatDuration(int minutes) {
  final hours = minutes ~/ Duration.minutesPerHour;
  final remainingMinutes = minutes % Duration.minutesPerHour;
  if (hours == 0) return '$remainingMinutes min';
  if (remainingMinutes == 0) return '${hours}h';
  return '${hours}h ${remainingMinutes}m';
}

TimeOfDay _asTimeOfDay(int minutes) {
  return TimeOfDay(
    hour: minutes ~/ Duration.minutesPerHour,
    minute: minutes % Duration.minutesPerHour,
  );
}
