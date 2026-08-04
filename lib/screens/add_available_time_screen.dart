import 'package:flutter/material.dart';

import '../models/available_time_block.dart';

class AddAvailableTimeScreen extends StatefulWidget {
  const AddAvailableTimeScreen({
    required this.existingBlocks,
    this.initialBlock,
    super.key,
  });

  final AvailableTimeBlock? initialBlock;
  final List<AvailableTimeBlock> existingBlocks;

  @override
  State<AddAvailableTimeScreen> createState() => _AddAvailableTimeScreenState();
}

class _AddAvailableTimeScreenState extends State<AddAvailableTimeScreen> {
  static const _minutesPerDay = 24 * 60;
  static const _stepMinutes = 15;

  late int _startMinutes;
  late int _endMinutes;
  String? _errorMessage;

  bool get _isEditing => widget.initialBlock != null;

  @override
  void initState() {
    super.initState();
    _startMinutes = widget.initialBlock?.startMinutes ?? 9 * 60;
    _endMinutes = widget.initialBlock?.endMinutes ?? 12 * 60;
  }

  Future<void> _chooseTime({required bool isStart}) async {
    final currentMinutes = isStart ? _startMinutes : _endMinutes;
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _asTimeOfDay(currentMinutes),
      helpText: isStart ? 'Select start time' : 'Select end time',
    );

    if (selectedTime == null) return;
    final selectedMinutes = selectedTime.hour * 60 + selectedTime.minute;
    setState(() {
      if (isStart) {
        _startMinutes = selectedMinutes;
      } else {
        _endMinutes = selectedMinutes;
      }
      _errorMessage = null;
    });
  }

  void _changeTime({required bool isStart, required int change}) {
    setState(() {
      if (isStart) {
        _startMinutes = (_startMinutes + change)
            .clamp(0, _minutesPerDay - _stepMinutes)
            .toInt();
      } else {
        _endMinutes = (_endMinutes + change)
            .clamp(0, _minutesPerDay - _stepMinutes)
            .toInt();
      }
      _errorMessage = null;
    });
  }

  void _saveBlock() {
    if (_endMinutes <= _startMinutes) {
      setState(() {
        _errorMessage = 'End time must be later than start time.';
      });
      return;
    }

    final block = AvailableTimeBlock(
      startMinutes: _startMinutes,
      endMinutes: _endMinutes,
    );
    if (widget.existingBlocks.any(block.overlaps)) {
      setState(() {
        _errorMessage = 'This time overlaps an existing available-time window.';
      });
      return;
    }

    Navigator.of(context).pop(block);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Available Time' : 'Add Available Time'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              'Choose a window when Ditto can schedule your tasks.',
              style: textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _TimeStepper(
              label: 'Start time',
              minutes: _startMinutes,
              decreaseKey: const Key('decrease-start-time'),
              timeKey: const Key('start-time-button'),
              increaseKey: const Key('increase-start-time'),
              canDecrease: _startMinutes > 0,
              canIncrease: _startMinutes < _minutesPerDay - _stepMinutes,
              onDecrease: () =>
                  _changeTime(isStart: true, change: -_stepMinutes),
              onChoose: () => _chooseTime(isStart: true),
              onIncrease: () =>
                  _changeTime(isStart: true, change: _stepMinutes),
            ),
            const SizedBox(height: 16),
            _TimeStepper(
              label: 'End time',
              minutes: _endMinutes,
              decreaseKey: const Key('decrease-end-time'),
              timeKey: const Key('end-time-button'),
              increaseKey: const Key('increase-end-time'),
              canDecrease: _endMinutes > 0,
              canIncrease: _endMinutes < _minutesPerDay - _stepMinutes,
              onDecrease: () =>
                  _changeTime(isStart: false, change: -_stepMinutes),
              onChoose: () => _chooseTime(isStart: false),
              onIncrease: () =>
                  _changeTime(isStart: false, change: _stepMinutes),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              key: const Key('save-time-block-button'),
              onPressed: _saveBlock,
              child: Text(_isEditing ? 'Save changes' : 'Save time'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeStepper extends StatelessWidget {
  const _TimeStepper({
    required this.label,
    required this.minutes,
    required this.decreaseKey,
    required this.timeKey,
    required this.increaseKey,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onChoose,
    required this.onIncrease,
  });

  final String label;
  final int minutes;
  final Key decreaseKey;
  final Key timeKey;
  final Key increaseKey;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onChoose;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final formattedTime = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(_asTimeOfDay(minutes));

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.outlined(
                key: decreaseKey,
                tooltip: 'Move $label earlier',
                onPressed: canDecrease ? onDecrease : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: TextButton(
                  key: timeKey,
                  onPressed: onChoose,
                  child: Text(
                    formattedTime,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
              IconButton.outlined(
                key: increaseKey,
                tooltip: 'Move $label later',
                onPressed: canIncrease ? onIncrease : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

TimeOfDay _asTimeOfDay(int minutes) {
  return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
}
