import 'package:flutter/material.dart';

import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import 'app_shell.dart';

class DittoApp extends StatelessWidget {
  const DittoApp({this.storageService, super.key});

  final LocalStorageService? storageService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ditto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppShell(storageService: storageService),
    );
  }
}
