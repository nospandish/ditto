import 'package:flutter/material.dart';

import '../widgets/screen_empty_state.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: const SafeArea(
        child: ScreenEmptyState(
          icon: Icons.calendar_today_rounded,
          title: 'Make today manageable.',
          message:
              'Your schedule will appear here after you add tasks and available time.',
          actionIcon: Icons.add_task_rounded,
          actionLabel: 'Add your first task',
        ),
      ),
    );
  }
}
