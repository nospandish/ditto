import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/available_time_block.dart';

const double _startOfDayAngle = -math.pi / 2;

@visibleForTesting
double availableTimeAngleForMinutes(int minutes) {
  return _startOfDayAngle + (minutes / Duration.minutesPerDay) * 2 * math.pi;
}

class AvailableTimeClock extends StatelessWidget {
  const AvailableTimeClock({required this.blocks, super.key});

  final List<AvailableTimeBlock> blocks;

  int get _totalMinutes =>
      blocks.fold(0, (total, block) => total + block.durationMinutes);

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final sortedBlocks = [...blocks]
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    final semanticsLabel = _buildSemanticsLabel(
      blocks: sortedBlocks,
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
                dimension: 252,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        size: const Size.square(252),
                        painter: _AvailableTimeClockPainter(
                          blocks: sortedBlocks,
                          availableColor: Theme.of(context).colorScheme.primary,
                          unavailableColor: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.72),
                          tickColor: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const _ClockLabel(
                      label: '12 AM',
                      alignment: Alignment.topCenter,
                    ),
                    const _ClockLabel(
                      label: '6 AM',
                      alignment: Alignment.centerRight,
                    ),
                    const _ClockLabel(
                      label: '12 PM',
                      alignment: Alignment.bottomCenter,
                    ),
                    const _ClockLabel(
                      label: '6 PM',
                      alignment: Alignment.centerLeft,
                    ),
                    _ClockCenter(totalMinutes: _totalMinutes),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const _ClockLegend(),
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
    required this.availableColor,
    required this.unavailableColor,
    required this.tickColor,
  }) : blocks = List.unmodifiable(blocks);

  final List<AvailableTimeBlock> blocks;
  final Color availableColor;
  final Color unavailableColor;
  final Color tickColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 38;
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
        unavailableColor != oldDelegate.unavailableColor ||
        tickColor != oldDelegate.tickColor ||
        blocks.length != oldDelegate.blocks.length) {
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
    return false;
  }
}

class _ClockLabel extends StatelessWidget {
  const _ClockLabel({required this.label, required this.alignment});

  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
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
  const _ClockLegend();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
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
  required MaterialLocalizations localizations,
  required int totalMinutes,
}) {
  final buffer = StringBuffer(
    'Available time clock. ${_formatDuration(totalMinutes)} available today.',
  );
  for (final block in blocks) {
    final start = localizations.formatTimeOfDay(
      _asTimeOfDay(block.startMinutes),
    );
    final end = localizations.formatTimeOfDay(_asTimeOfDay(block.endMinutes));
    buffer.write(' Available from $start to $end.');
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
