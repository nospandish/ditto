import 'package:flutter/material.dart';

import '../widgets/screen_empty_state.dart';

class AvailableTimeScreen extends StatelessWidget {
  const AvailableTimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Time')),
      body: const SafeArea(
        child: ScreenEmptyState(
          icon: Icons.schedule_rounded,
          title: 'When are you free?',
          message:
              'Your available time windows will appear here once you add them.',
          actionIcon: Icons.add_rounded,
          actionLabel: 'Add available time',
        ),
      ),
    );
  }
}
