import 'package:flutter/material.dart';

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
  }

  @override
  void dispose() {
    _nameController.dispose();
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
              Row(
                children: [
                  Expanded(
                    child: _DurationStepper(
                      label: 'Minimum',
                      minutes: _minimumMinutes,
                      decreaseKey: const Key('decrease-minimum-duration'),
                      increaseKey: const Key('increase-minimum-duration'),
                      onChanged: (minutes) {
                        setState(() {
                          _minimumMinutes = minutes;
                          _durationError = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DurationStepper(
                      label: 'Maximum',
                      minutes: _maximumMinutes,
                      decreaseKey: const Key('decrease-maximum-duration'),
                      increaseKey: const Key('increase-maximum-duration'),
                      onChanged: (minutes) {
                        setState(() {
                          _maximumMinutes = minutes;
                          _durationError = null;
                        });
                      },
                    ),
                  ),
                ],
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

class _DurationStepper extends StatelessWidget {
  const _DurationStepper({
    required this.label,
    required this.minutes,
    required this.decreaseKey,
    required this.increaseKey,
    required this.onChanged,
  });

  final String label;
  final int minutes;
  final Key decreaseKey;
  final Key increaseKey;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: decreaseKey,
                tooltip: 'Decrease $label time',
                onPressed: minutes > 15 ? () => onChanged(minutes - 15) : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Text(
                  _formatDuration(minutes),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                key: increaseKey,
                tooltip: 'Increase $label time',
                onPressed: () => onChanged(minutes + 15),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
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
