import 'package:flutter/material.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Make today manageable.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Add your tasks and available time, then Ditto will build a realistic plan for your day.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('Add your first task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
