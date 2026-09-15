import 'dart:async';

import 'package:flutter/material.dart';

import '../models/available_time_block.dart';
import '../models/ditto_task.dart';
import '../models/saved_plan.dart';
import '../models/scheduled_task.dart';
import '../screens/add_available_time_screen.dart';
import '../screens/add_task_screen.dart';
import '../screens/available_time_screen.dart';
import '../screens/tasks_screen.dart';
import '../screens/today_screen.dart';
import '../services/local_storage_service.dart';
import '../services/schedule_service.dart';

class AppShell extends StatefulWidget {
  const AppShell({this.storageService, this.currentMinutesProvider, super.key});

  final LocalStorageService? storageService;
  final int Function()? currentMinutesProvider;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final List<DittoTask> _tasks = [];
  final List<AvailableTimeBlock> _availableTimeBlocks = [];
  final List<SavedPlan> _savedPlans = [];
  final ScheduleService _scheduleService = const ScheduleService();
  String? _activePlanId;
  LocalStorageService? _storageService;
  bool _isLoading = true;

  int get _currentMinutes =>
      widget.currentMinutesProvider?.call() ?? _minutesNow();

  SavedPlan? get _activePlan {
    for (final plan in _savedPlans) {
      if (plan.id == _activePlanId) return plan;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadSavedData());
  }

  Future<void> _loadSavedData() async {
    try {
      final storage =
          widget.storageService ?? await LocalStorageService.create();
      final tasks = storage.loadTasks();
      final availableTime = storage.loadAvailableTime()
        ..sort(
          (first, second) => first.startMinutes.compareTo(second.startMinutes),
        );
      final plans = storage.loadPlans();
      var activePlanId = storage.loadActivePlanId();
      if (plans.isEmpty && storage.loadHasGeneratedPlan()) {
        final createdAt = DateTime.now();
        final migratedPlan = SavedPlan(
          id: 'migrated-${createdAt.microsecondsSinceEpoch}',
          name: 'Imported plan',
          createdAt: createdAt,
          tasks: tasks,
          availableTime: availableTime,
          scheduleResult: _scheduleService.buildSchedule(
            tasks: tasks,
            availableTime: availableTime,
          ),
        );
        plans.add(migratedPlan);
        activePlanId = migratedPlan.id;
        await Future.wait([
          storage.savePlans(plans),
          storage.saveActivePlanId(activePlanId),
        ]);
      } else if (plans.isNotEmpty &&
          !plans.any((plan) => plan.id == activePlanId)) {
        activePlanId = plans.last.id;
        await storage.saveActivePlanId(activePlanId);
      }
      if (!mounted) return;
      setState(() {
        _storageService = storage;
        _tasks.addAll(tasks);
        _availableTimeBlocks.addAll(availableTime);
        _savedPlans.addAll(plans);
        _activePlanId = activePlanId;
        _isLoading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showStorageError(
            'Ditto could not load saved data. You can still use the app.',
          );
        }
      });
    }
  }

  Future<void> _saveTasks() async {
    try {
      await _storageService?.saveTasks(_tasks);
    } on Object {
      if (mounted) _showStorageError();
    }
  }

  Future<void> _saveAvailableTime() async {
    try {
      await _storageService?.saveAvailableTime(_availableTimeBlocks);
    } on Object {
      if (mounted) _showStorageError();
    }
  }

  Future<void> _savePlans() async {
    try {
      await Future.wait([
        _storageService?.savePlans(_savedPlans) ?? Future<void>.value(),
        _storageService?.saveActivePlanId(_activePlanId) ??
            Future<void>.value(),
        _storageService?.saveHasGeneratedPlan(_savedPlans.isNotEmpty) ??
            Future<void>.value(),
      ]);
    } on Object {
      if (mounted) _showStorageError();
    }
  }

  Future<void> _saveWorkspaceAndPlans() async {
    try {
      await Future.wait([
        _storageService?.saveTasks(_tasks) ?? Future<void>.value(),
        _storageService?.saveAvailableTime(_availableTimeBlocks) ??
            Future<void>.value(),
        _storageService?.savePlans(_savedPlans) ?? Future<void>.value(),
        _storageService?.saveActivePlanId(_activePlanId) ??
            Future<void>.value(),
        _storageService?.saveHasGeneratedPlan(_savedPlans.isNotEmpty) ??
            Future<void>.value(),
      ]);
    } on Object {
      if (mounted) _showStorageError();
    }
  }

  void _showStorageError([
    String message = 'Ditto could not save your changes. Please try again.',
  ]) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _generatePlan() async {
    final name = await _requestPlanName(suggestedName: _nextPlanName());
    if (!mounted || name == null) return;

    final plan = _buildPlan(name);
    setState(() {
      _savedPlans.add(plan);
      _activePlanId = plan.id;
    });
    await _savePlans();
  }

  SavedPlan _buildPlan(String name, {String? parentPlanId}) {
    final createdAt = DateTime.now();
    final result = _scheduleService.buildSchedule(
      tasks: _tasks,
      availableTime: _availableTimeBlocks,
    );
    return SavedPlan(
      id: '${createdAt.microsecondsSinceEpoch}-${_savedPlans.length}',
      name: name,
      createdAt: createdAt,
      parentPlanId: parentPlanId,
      tasks: _tasks,
      availableTime: _availableTimeBlocks,
      scheduleResult: result,
    );
  }

  Future<void> _regenerateRemaining() async {
    final activePlan = _activePlan;
    if (activePlan == null) return;

    final usesCurrentWorkspace = activePlan.matchesInputs(
      tasks: _tasks,
      availableTime: _availableTimeBlocks,
    );
    final sourceTasks = usesCurrentWorkspace ? activePlan.tasks : _tasks;
    final sourceAvailableTime = usesCurrentWorkspace
        ? activePlan.availableTime
        : _availableTimeBlocks;
    final resolvedTasks = <DittoTask>{};
    final historyTasks = [
      if (usesCurrentWorkspace) ...activePlan.scheduleResult.historyTasks,
    ];
    for (final item
        in usesCurrentWorkspace
            ? activePlan.scheduleResult.scheduledTasks
            : const <ScheduledTask>[]) {
      if (item.status != ScheduledTaskStatus.planned) {
        historyTasks.add(item);
        resolvedTasks.add(item.task);
      }
    }
    final remainingTasks = sourceTasks
        .where((task) => !resolvedTasks.contains(task))
        .toList(growable: false);
    final remainingResult = _scheduleService
        .buildRemainingSchedule(
          tasks: remainingTasks,
          availableTime: sourceAvailableTime,
          currentMinutes: _currentMinutes,
        )
        .copyWith(historyTasks: historyTasks);
    final createdAt = DateTime.now();
    final regeneratedPlan = SavedPlan(
      id: '${createdAt.microsecondsSinceEpoch}-${_savedPlans.length}',
      name: activePlan.name,
      createdAt: createdAt,
      parentPlanId: activePlan.id,
      rootPlanId: activePlan.rootPlanId,
      tasks: sourceTasks,
      availableTime: sourceAvailableTime,
      scheduleResult: remainingResult,
    );

    setState(() {
      _savedPlans.add(regeneratedPlan);
      _activePlanId = regeneratedPlan.id;
      _tasks
        ..clear()
        ..addAll(regeneratedPlan.tasks);
      _availableTimeBlocks
        ..clear()
        ..addAll(regeneratedPlan.availableTime);
    });
    await _saveWorkspaceAndPlans();
  }

  Future<void> _undoPlanVersion() async {
    final activePlan = _activePlan;
    final parentPlanId = activePlan?.parentPlanId;
    if (parentPlanId == null) return;
    SavedPlan? parentPlan;
    for (final plan in _savedPlans) {
      if (plan.id == parentPlanId) {
        parentPlan = plan;
        break;
      }
    }
    if (parentPlan == null) return;
    final targetPlan = parentPlan;

    setState(() {
      _activePlanId = targetPlan.id;
      _tasks
        ..clear()
        ..addAll(targetPlan.tasks);
      _availableTimeBlocks
        ..clear()
        ..addAll(targetPlan.availableTime);
    });
    await _saveWorkspaceAndPlans();
  }

  Future<void> _selectPlan(String planId) async {
    if (_activePlanId == planId) return;
    final targetIndex = _savedPlans.indexWhere((plan) => plan.id == planId);
    if (targetIndex == -1) return;
    final targetPlan = _savedPlans[targetIndex];
    final activePlan = _activePlan;

    if (activePlan != null &&
        !activePlan.matchesInputs(
          tasks: _tasks,
          availableTime: _availableTimeBlocks,
        )) {
      final choice = await _requestPlanSwitchChoice();
      if (!mounted || choice == null || choice == _PlanSwitchChoice.cancel) {
        return;
      }
      if (choice == _PlanSwitchChoice.saveAsNew) {
        final name = await _requestPlanName(suggestedName: _nextPlanName());
        if (!mounted || name == null) return;
        _savedPlans.add(_buildPlan(name));
      }
    }

    setState(() {
      _activePlanId = targetPlan.id;
      _tasks
        ..clear()
        ..addAll(targetPlan.tasks);
      _availableTimeBlocks
        ..clear()
        ..addAll(targetPlan.availableTime);
    });
    await _saveWorkspaceAndPlans();
  }

  Future<void> _deletePlan(SavedPlan plan) async {
    if (_savedPlans.any((candidate) => candidate.parentPlanId == plan.id)) {
      _showStorageError(
        'Delete newer versions first so this plan history stays connected.',
      );
      return;
    }
    SavedPlan? fallbackPlan;
    setState(() {
      _savedPlans.removeWhere((candidate) => candidate.id == plan.id);
      if (_activePlanId == plan.id) {
        fallbackPlan = _savedPlans.isEmpty ? null : _savedPlans.last;
        _activePlanId = fallbackPlan?.id;
        if (fallbackPlan != null) {
          _tasks
            ..clear()
            ..addAll(fallbackPlan!.tasks);
          _availableTimeBlocks
            ..clear()
            ..addAll(fallbackPlan!.availableTime);
        }
      }
    });
    if (fallbackPlan == null) {
      await _savePlans();
    } else {
      await _saveWorkspaceAndPlans();
    }
  }

  Future<void> _updateScheduledTaskStatus(
    ScheduledTask task,
    ScheduledTaskStatus status,
  ) async {
    final activePlan = _activePlan;
    if (activePlan == null) return;

    final planIndex = _savedPlans.indexWhere(
      (plan) => plan.id == activePlan.id,
    );
    if (planIndex == -1) return;

    final scheduledTasks = [
      for (final item in activePlan.scheduleResult.scheduledTasks)
        identical(item, task) ? item.copyWith(status: status) : item,
    ];
    final updatedPlan = activePlan.copyWith(
      scheduleResult: activePlan.scheduleResult.copyWith(
        scheduledTasks: scheduledTasks,
      ),
    );

    setState(() => _savedPlans[planIndex] = updatedPlan);
    await _savePlans();
  }

  Future<void> _renamePlan(SavedPlan plan) async {
    final name = await _requestPlanName(
      suggestedName: plan.name,
      planBeingRenamed: plan,
    );
    if (!mounted || name == null || name == plan.name) return;
    final index = _savedPlans.indexWhere(
      (candidate) => candidate.id == plan.id,
    );
    if (index == -1) return;
    setState(() => _savedPlans[index] = plan.copyWith(name: name));
    await _savePlans();
  }

  Future<void> _renamePlanVersion(SavedPlan plan) async {
    final suggestedName =
        plan.versionName ??
        (plan.parentPlanId == null ? 'Original plan' : 'Regenerated version');
    final name = await _requestPlanName(
      suggestedName: suggestedName,
      dialogTitle: 'Name this version',
      reservedNames: const {},
    );
    if (!mounted || name == null || name == plan.versionName) return;
    final index = _savedPlans.indexWhere(
      (candidate) => candidate.id == plan.id,
    );
    if (index == -1) return;
    setState(() => _savedPlans[index] = plan.copyWith(versionName: name));
    await _savePlans();
  }

  String _nextPlanName() {
    final usedNames = _savedPlans
        .map((plan) => plan.name.toLowerCase())
        .toSet();
    var number = 1;
    while (usedNames.contains('plan $number')) {
      number++;
    }
    return 'Plan $number';
  }

  Future<String?> _requestPlanName({
    required String suggestedName,
    String dialogTitle = 'Name this plan',
    Set<String>? reservedNames,
    SavedPlan? planBeingRenamed,
  }) {
    final names =
        reservedNames ??
        {
          for (final plan in _savedPlans)
            if (plan.id != planBeingRenamed?.id) plan.name.toLowerCase(),
        };
    return showDialog<String>(
      context: context,
      builder: (context) => _PlanNameDialog(
        initialName: suggestedName,
        dialogTitle: dialogTitle,
        reservedNames: names,
      ),
    );
  }

  Future<_PlanSwitchChoice?> _requestPlanSwitchChoice() {
    return showDialog<_PlanSwitchChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save this changed setup?'),
        content: const Text(
          'Switching plans will replace the current tasks and available time. '
          'You can save these changes as a new plan first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _PlanSwitchChoice.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('discard-plan-changes'),
            onPressed: () => Navigator.pop(context, _PlanSwitchChoice.discard),
            child: const Text('Switch without saving'),
          ),
          FilledButton(
            key: const Key('save-setup-as-plan'),
            onPressed: () =>
                Navigator.pop(context, _PlanSwitchChoice.saveAsNew),
            child: const Text('Save as new plan'),
          ),
        ],
      ),
    );
  }

  Future<void> _openTaskEditor([DittoTask? existingTask]) async {
    final editedTask = await Navigator.of(context).push<DittoTask>(
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(
          initialTask: existingTask,
          commonTaskNames: _commonTaskNames,
        ),
      ),
    );

    if (!mounted || editedTask == null) return;

    setState(() {
      if (existingTask == null) {
        _tasks.add(editedTask);
        return;
      }

      final taskIndex = _tasks.indexOf(existingTask);
      if (taskIndex != -1) _tasks[taskIndex] = editedTask;
    });
    await _saveTasks();
  }

  List<String> get _commonTaskNames {
    final counts = <String, int>{};
    final displayNames = <String, String>{};
    for (final task in _tasks) {
      final normalized = task.name.trim().toLowerCase();
      if (normalized.isEmpty) continue;
      counts[normalized] = (counts[normalized] ?? 0) + 1;
      displayNames.putIfAbsent(normalized, () => task.name.trim());
    }

    final names = counts.keys.toList()
      ..sort((first, second) {
        final countComparison = counts[second]!.compareTo(counts[first]!);
        return countComparison != 0
            ? countComparison
            : displayNames[first]!.compareTo(displayNames[second]!);
      });
    return [for (final name in names.take(8)) displayNames[name]!];
  }

  void _deleteTask(DittoTask task) {
    setState(() {
      _tasks.remove(task);
    });
    unawaited(_saveTasks());
  }

  Future<void> _openAvailableTimeEditor([
    AvailableTimeBlock? existingBlock,
  ]) async {
    final otherBlocks = _availableTimeBlocks
        .where((block) => !identical(block, existingBlock))
        .toList(growable: false);
    final editedBlock = await Navigator.of(context).push<AvailableTimeBlock>(
      MaterialPageRoute(
        builder: (context) => AddAvailableTimeScreen(
          initialBlock: existingBlock,
          existingBlocks: otherBlocks,
        ),
      ),
    );

    if (!mounted || editedBlock == null) return;

    setState(() {
      if (existingBlock == null) {
        _availableTimeBlocks.add(editedBlock);
      } else {
        final blockIndex = _availableTimeBlocks.indexOf(existingBlock);
        if (blockIndex != -1) _availableTimeBlocks[blockIndex] = editedBlock;
      }
      _availableTimeBlocks.sort(
        (first, second) => first.startMinutes.compareTo(second.startMinutes),
      );
    });
    await _saveAvailableTime();
  }

  void _deleteAvailableTimeBlock(AvailableTimeBlock block) {
    setState(() {
      _availableTimeBlocks.remove(block);
    });
    unawaited(_saveAvailableTime());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(key: Key('storage-loading')),
        ),
      );
    }

    final activePlan = _activePlan;
    final isActivePlanOutdated =
        activePlan != null &&
        !activePlan.matchesInputs(
          tasks: _tasks,
          availableTime: _availableTimeBlocks,
        );
    final currentScheduleResult = isActivePlanOutdated
        ? null
        : activePlan?.scheduleResult;
    final showScheduleWarning =
        currentScheduleResult?.hasImpossibleMustCompleteTasks ?? false;
    final minutesShort = currentScheduleResult?.minutesShort ?? 0;

    final screens = <Widget>[
      TodayScreen(
        hasTasks: _tasks.isNotEmpty,
        hasAvailableTime: _availableTimeBlocks.isNotEmpty,
        scheduleResult: activePlan?.scheduleResult,
        savedPlans: _savedPlans,
        activePlan: activePlan,
        isActivePlanOutdated: isActivePlanOutdated,
        onAddTask: _openTaskEditor,
        onAddAvailableTime: _openAvailableTimeEditor,
        onReviewTasks: () => setState(() => _selectedIndex = 1),
        onGeneratePlan: _generatePlan,
        onSelectPlan: _selectPlan,
        onRenamePlan: _renamePlan,
        onRenamePlanVersion: _renamePlanVersion,
        onDeletePlan: _deletePlan,
        onUpdateTaskStatus: _updateScheduledTaskStatus,
        onRegenerateRemaining: activePlan == null ? null : _regenerateRemaining,
        onUndoPlanVersion:
            activePlan?.parentPlanId != null &&
                _savedPlans.any((plan) => plan.id == activePlan!.parentPlanId)
            ? _undoPlanVersion
            : null,
        currentMinutes: _currentMinutes,
      ),
      TasksScreen(
        tasks: _tasks,
        minutesShort: minutesShort,
        showScheduleWarning: showScheduleWarning,
        onAddTask: _openTaskEditor,
        onEditTask: _openTaskEditor,
        onDeleteTask: _deleteTask,
      ),
      AvailableTimeScreen(
        blocks: _availableTimeBlocks,
        scheduledTasks: currentScheduleResult?.scheduledTasks ?? const [],
        minutesShort: minutesShort,
        showScheduleWarning: showScheduleWarning,
        onAddBlock: _openAvailableTimeEditor,
        onEditBlock: _openAvailableTimeEditor,
        onDeleteBlock: _deleteAvailableTimeBlock,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today_rounded),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist_rounded),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule_rounded),
            label: 'Time',
          ),
        ],
      ),
    );
  }
}

int _minutesNow() {
  final now = DateTime.now();
  return now.hour * 60 + now.minute;
}

enum _PlanSwitchChoice { saveAsNew, discard, cancel }

class _PlanNameDialog extends StatefulWidget {
  const _PlanNameDialog({
    required this.initialName,
    required this.dialogTitle,
    required this.reservedNames,
  });

  final String initialName;
  final String dialogTitle;
  final Set<String> reservedNames;

  @override
  State<_PlanNameDialog> createState() => _PlanNameDialogState();
}

class _PlanNameDialogState extends State<_PlanNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName)
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.initialName.length,
      );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, _nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dialogTitle),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('plan-name-field'),
          controller: _nameController,
          autofocus: true,
          maxLength: 40,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Plan name',
            hintText: 'After-school plan',
          ),
          validator: (value) {
            final name = value?.trim() ?? '';
            if (name.isEmpty) return 'Enter a plan name.';
            if (widget.reservedNames.contains(name.toLowerCase())) {
              return 'Choose a different plan name.';
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('confirm-plan-name'),
          onPressed: _submit,
          child: const Text('Save plan'),
        ),
      ],
    );
  }
}
