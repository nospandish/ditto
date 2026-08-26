import 'dart:async';

import 'package:flutter/material.dart';

import '../models/available_time_block.dart';
import '../models/ditto_task.dart';
import '../models/schedule_build_result.dart';
import '../screens/add_available_time_screen.dart';
import '../screens/add_task_screen.dart';
import '../screens/available_time_screen.dart';
import '../screens/tasks_screen.dart';
import '../screens/today_screen.dart';
import '../services/local_storage_service.dart';
import '../services/schedule_service.dart';

class AppShell extends StatefulWidget {
  const AppShell({this.storageService, super.key});

  final LocalStorageService? storageService;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final List<DittoTask> _tasks = [];
  final List<AvailableTimeBlock> _availableTimeBlocks = [];
  final ScheduleService _scheduleService = const ScheduleService();
  ScheduleBuildResult? _scheduleResult;
  LocalStorageService? _storageService;
  bool _isLoading = true;

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
      if (!mounted) return;
      setState(() {
        _storageService = storage;
        _tasks.addAll(tasks);
        _availableTimeBlocks.addAll(availableTime);
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

  void _showStorageError([
    String message = 'Ditto could not save your changes. Please try again.',
  ]) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _generatePlan() {
    setState(() {
      _scheduleResult = _scheduleService.buildSchedule(
        tasks: _tasks,
        availableTime: _availableTimeBlocks,
      );
    });
  }

  Future<void> _openTaskEditor([DittoTask? existingTask]) async {
    final editedTask = await Navigator.of(context).push<DittoTask>(
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(initialTask: existingTask),
      ),
    );

    if (!mounted || editedTask == null) return;

    setState(() {
      if (existingTask == null) {
        _tasks.add(editedTask);
        _scheduleResult = null;
        return;
      }

      final taskIndex = _tasks.indexOf(existingTask);
      if (taskIndex != -1) _tasks[taskIndex] = editedTask;
      _scheduleResult = null;
    });
    await _saveTasks();
  }

  void _deleteTask(DittoTask task) {
    setState(() {
      _tasks.remove(task);
      _scheduleResult = null;
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
      _scheduleResult = null;
    });
    await _saveAvailableTime();
  }

  void _deleteAvailableTimeBlock(AvailableTimeBlock block) {
    setState(() {
      _availableTimeBlocks.remove(block);
      _scheduleResult = null;
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

    final screens = <Widget>[
      TodayScreen(
        hasTasks: _tasks.isNotEmpty,
        hasAvailableTime: _availableTimeBlocks.isNotEmpty,
        scheduleResult: _scheduleResult,
        onAddTask: _openTaskEditor,
        onAddAvailableTime: _openAvailableTimeEditor,
        onReviewTasks: () => setState(() => _selectedIndex = 1),
        onGeneratePlan: _generatePlan,
      ),
      TasksScreen(
        tasks: _tasks,
        onAddTask: _openTaskEditor,
        onEditTask: _openTaskEditor,
        onDeleteTask: _deleteTask,
      ),
      AvailableTimeScreen(
        blocks: _availableTimeBlocks,
        scheduledTasks: _scheduleResult?.scheduledTasks ?? const [],
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
