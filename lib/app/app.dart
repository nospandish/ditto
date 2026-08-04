import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_shell.dart';

class DittoApp extends StatelessWidget {
  const DittoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ditto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppShell(),
    );
  }
}
