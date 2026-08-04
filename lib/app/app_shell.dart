import 'package:flutter/material.dart';

import '../models/available_time_block.dart';
import '../models/ditto_task.dart';
import '../models/scheduled_task.dart';
import '../screens/add_available_time_screen.dart';
import '../screens/add_task_screen.dart';
import '../screens/available_time_screen.dart';
import '../screens/tasks_screen.dart';
import '../screens/today_screen.dart';
import '../services/schedule_service.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final List<DittoTask> _tasks = [];
  final List<AvailableTimeBlock> _availableTimeBlocks = [];
  final ScheduleService _scheduleService = const ScheduleService();
  List<ScheduledTask> _schedule = [];

  void _generatePlan() {
    setState(() {
      _schedule = _scheduleService.buildSchedule(
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
        _schedule = [];
        return;
      }

      final taskIndex = _tasks.indexOf(existingTask);
      if (taskIndex != -1) _tasks[taskIndex] = editedTask;
      _schedule = [];
    });
  }

  void _deleteTask(DittoTask task) {
    setState(() {
      _tasks.remove(task);
      _schedule = [];
    });
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
      _schedule = [];
    });
  }

  void _deleteAvailableTimeBlock(AvailableTimeBlock block) {
    setState(() {
      _availableTimeBlocks.remove(block);
      _schedule = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      TodayScreen(
        hasTasks: _tasks.isNotEmpty,
        hasAvailableTime: _availableTimeBlocks.isNotEmpty,
        schedule: _schedule,
        onAddTask: _openTaskEditor,
        onAddAvailableTime: _openAvailableTimeEditor,
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
