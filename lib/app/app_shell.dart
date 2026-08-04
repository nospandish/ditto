import 'package:flutter/material.dart';

import '../models/ditto_task.dart';
import '../screens/add_task_screen.dart';
import '../screens/available_time_screen.dart';
import '../screens/tasks_screen.dart';
import '../screens/today_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final List<DittoTask> _tasks = [];

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
        return;
      }

      final taskIndex = _tasks.indexOf(existingTask);
      if (taskIndex != -1) _tasks[taskIndex] = editedTask;
    });
  }

  void _deleteTask(DittoTask task) {
    setState(() => _tasks.remove(task));
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const TodayScreen(),
      TasksScreen(
        tasks: _tasks,
        onAddTask: _openTaskEditor,
        onEditTask: _openTaskEditor,
        onDeleteTask: _deleteTask,
      ),
      const AvailableTimeScreen(),
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
