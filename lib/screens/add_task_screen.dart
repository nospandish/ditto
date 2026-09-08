import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/ditto_task.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({this.initialTask, super.key});

  final DittoTask? initialTask;

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late DateTime? _dueDate;
  late int _minimumMinutes;
  late int _maximumMinutes;
  late TaskImportance _importance;
  late final TextEditingController _minimumController;
  late final TextEditingController _maximumController;
  String? _durationError;

  bool get _isEditing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _nameController = TextEditingController(text: task?.name);
    _dueDate = task?.dueDate;
    _minimumMinutes = task?.minimumMinutes ?? 30;
    _maximumMinutes = task?.maximumMinutes ?? 60;
    _importance = task?.importance ?? TaskImportance.mustComplete;
    _minimumController = TextEditingController(text: '$_minimumMinutes');
    _maximumController = TextEditingController(text: '$_maximumMinutes');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minimumController.dispose();
    _maximumController.dispose();
    super.dispose();
  }

  Future<void> _chooseDueDate() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10, 12, 31),
      helpText: 'Select task deadline',
    );

    if (selectedDate != null) {
      setState(() => _dueDate = DateUtils.dateOnly(selectedDate));
    }
  }

  void _saveTask() {
    _commitTypedDurations();
    final formIsValid = _formKey.currentState?.validate() ?? false;
    final durationsAreValid = _maximumMinutes >= _minimumMinutes;

    setState(() {
      _durationError = durationsAreValid
          ? null
          : 'Maximum time must be at least the minimum time.';
    });

    if (!formIsValid || !durationsAreValid) return;

    Navigator.of(context).pop(
      DittoTask(
        name: _nameController.text.trim(),
        dueDate: _dueDate,
        minimumMinutes: _minimumMinutes,
        maximumMinutes: _maximumMinutes,
        importance: _importance,
      ),
    );
  }

  void _commitTypedDurations() {
    final minimum = _parseDuration(_minimumController.text);
    final maximum = _parseDuration(_maximumController.text);
    setState(() {
      if (minimum != null) _minimumMinutes = minimum;
      if (maximum != null) _maximumMinutes = maximum;
      _syncDurationControllers();
    });
  }

  void _setDurations({int? minimum, int? maximum}) {
    setState(() {
      _minimumMinutes = minimum ?? _minimumMinutes;
      _maximumMinutes = maximum ?? _maximumMinutes;
      _syncDurationControllers();
      _durationError = null;
    });
  }

  void _syncDurationControllers() {
    _minimumController.text = '$_minimumMinutes';
    _maximumController.text = '$_maximumMinutes';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Task' : 'Add Task')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text('Task name', style: textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('task-name-field'),
                controller: _nameController,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'e.g. Finish history outline',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a task name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text('Deadline', style: textTheme.titleSmall),
              const SizedBox(height: 8),
              _DeadlineField(
                dueDate: _dueDate,
                onChooseDate: _chooseDueDate,
                onClearDate: _dueDate == null
                    ? null
                    : () => setState(() => _dueDate = null),
              ),
              const SizedBox(height: 24),
              Text('Time needed', style: textTheme.titleSmall),
              const SizedBox(height: 8),
              _DurationRangeEditor(
                minimumMinutes: _minimumMinutes,
                maximumMinutes: _maximumMinutes,
                minimumController: _minimumController,
                maximumController: _maximumController,
                sliderColor: const Color(0xFFAFB208),
                onSliderChanged: (values) => _setDurations(
                  minimum: values.start.round(),
                  maximum: values.end.round(),
                ),
                onTypedChanged: () => setState(() => _durationError = null),
                onCommitTyped: _commitTypedDurations,
                onStep: (minimum, maximum) =>
                    _setDurations(minimum: minimum, maximum: maximum),
              ),
              if (_durationError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _durationError!,
                  style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text('Importance', style: textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final importance in TaskImportance.values)
                    ChoiceChip(
                      key: ValueKey('importance-${importance.name}'),
                      label: Text(importance.label),
                      selected: _importance == importance,
                      onSelected: (_) {
                        setState(() => _importance = importance);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton(
                key: const Key('save-task-button'),
                onPressed: _saveTask,
                child: Text(_isEditing ? 'Save changes' : 'Save task'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeadlineField extends StatelessWidget {
  const _DeadlineField({
    required this.dueDate,
    required this.onChooseDate,
    required this.onClearDate,
  });

  final DateTime? dueDate;
  final VoidCallback onChooseDate;
  final VoidCallback? onClearDate;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: ListTile(
        key: const Key('deadline-field'),
        onTap: onChooseDate,
        leading: const Icon(Icons.event_outlined),
        title: Text(dueDate == null ? 'No deadline' : _formatDate(dueDate!)),
        trailing: dueDate == null
            ? const Icon(Icons.chevron_right_rounded)
            : IconButton(
                tooltip: 'Remove deadline',
                onPressed: onClearDate,
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}

class _DurationRangeEditor extends StatelessWidget {
  const _DurationRangeEditor({
    required this.minimumMinutes,
    required this.maximumMinutes,
    required this.minimumController,
    required this.maximumController,
    required this.sliderColor,
    required this.onSliderChanged,
    required this.onTypedChanged,
    required this.onCommitTyped,
    required this.onStep,
  });

  final int minimumMinutes;
  final int maximumMinutes;
  final TextEditingController minimumController;
  final TextEditingController maximumController;
  final Color sliderColor;
  final ValueChanged<RangeValues> onSliderChanged;
  final VoidCallback onTypedChanged;
  final VoidCallback onCommitTyped;
  final void Function(int? minimum, int? maximum) onStep;

  @override
  Widget build(BuildContext context) {
    final sliderMinimum = minimumMinutes.toDouble().clamp(15, 480).toDouble();
    final sliderMaximum = maximumMinutes
        .toDouble()
        .clamp(sliderMinimum, 480)
        .toDouble();

    return Container(
      key: const Key('duration-range-editor'),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Drag to set a range, or type exact minutes.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          RangeSlider(
            key: const Key('duration-range-slider'),
            min: 15,
            max: 480,
            divisions: 31,
            labels: RangeLabels(
              _formatDuration(minimumMinutes),
              _formatDuration(maximumMinutes),
            ),
            values: RangeValues(sliderMinimum, sliderMaximum),
            activeColor: sliderColor,
            inactiveColor: sliderColor.withValues(alpha: 0.22),
            onChanged: onSliderChanged,
          ),
          Row(
            children: [
              Expanded(
                child: _DurationInput(
                  key: const Key('minimum-duration-input'),
                  label: 'Minimum',
                  controller: minimumController,
                  decreaseKey: const Key('decrease-minimum-duration'),
                  increaseKey: const Key('increase-minimum-duration'),
                  onChanged: onTypedChanged,
                  onSubmitted: onCommitTyped,
                  onDecrease: minimumMinutes > 15
                      ? () => onStep(minimumMinutes - 15, null)
                      : null,
                  onIncrease: () => onStep(minimumMinutes + 15, null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DurationInput(
                  key: const Key('maximum-duration-input'),
                  label: 'Maximum',
                  controller: maximumController,
                  decreaseKey: const Key('decrease-maximum-duration'),
                  increaseKey: const Key('increase-maximum-duration'),
                  onChanged: onTypedChanged,
                  onSubmitted: onCommitTyped,
                  onDecrease: maximumMinutes > 15
                      ? () => onStep(null, maximumMinutes - 15)
                      : null,
                  onIncrease: () => onStep(null, maximumMinutes + 15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DurationInput extends StatelessWidget {
  const _DurationInput({
    super.key,
    required this.label,
    required this.controller,
    required this.decreaseKey,
    required this.increaseKey,
    required this.onChanged,
    required this.onSubmitted,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final TextEditingController controller;
  final Key decreaseKey;
  final Key increaseKey;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      key: ValueKey('${label.toLowerCase()}-duration-field'),
      keyboardType: TextInputType.text,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9hm ]'))],
      textInputAction: TextInputAction.done,
      onChanged: (_) => onChanged(),
      onSubmitted: (_) => onSubmitted(),
      onEditingComplete: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'e.g. 90 or 1h 30m',
        suffixText: 'min',
        prefixIcon: IconButton(
          key: decreaseKey,
          tooltip: 'Decrease $label time',
          onPressed: onDecrease,
          icon: const Icon(Icons.remove_rounded),
        ),
        suffixIcon: IconButton(
          key: increaseKey,
          tooltip: 'Increase $label time',
          onPressed: onIncrease,
          icon: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}

String _formatDuration(int minutes) {
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (remainingMinutes == 0) return '${hours}h';
  return '${hours}h ${remainingMinutes}m';
}

int? _parseDuration(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  final minutesOnly = int.tryParse(normalized);
  if (minutesOnly != null) return minutesOnly.clamp(15, 480);

  final match = RegExp(
    r'^(?:(\d+)\s*h)?\s*(?:(\d+)\s*m)?$',
  ).firstMatch(normalized);
  if (match == null || (match.group(1) == null && match.group(2) == null)) {
    return null;
  }
  final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
  final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
  return (hours * 60 + minutes).clamp(15, 480);
}

String _formatDate(DateTime date) {
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
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
