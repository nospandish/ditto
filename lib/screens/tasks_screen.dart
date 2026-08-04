import 'package:flutter/material.dart';

import '../widgets/screen_empty_state.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: const SafeArea(
        child: ScreenEmptyState(
          icon: Icons.checklist_rounded,
          title: 'No tasks yet',
          message:
              'Tasks you add will be collected here so you can review them at a glance.',
          actionIcon: Icons.add_rounded,
          actionLabel: 'Add a task',
        ),
      ),
    );
  }
}
