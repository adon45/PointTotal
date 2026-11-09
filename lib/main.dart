import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/launch_screen.dart';
import 'state/entries_provider.dart';
import 'state/feedback_prompt_provider.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final entriesProvider = EntriesProvider();
  final feedbackPromptProvider = FeedbackPromptProvider();
  final themeModeController = ThemeModeController();
  await entriesProvider.load();
  await feedbackPromptProvider.load();
  await feedbackPromptProvider.recordOpen();
  await themeModeController.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: entriesProvider),
        ChangeNotifierProvider.value(value: feedbackPromptProvider),
        ChangeNotifierProvider.value(value: themeModeController),
      ],
      child: const ShootPointsApp(),
    ),
  );
}

class ShootPointsApp extends StatefulWidget {
  const ShootPointsApp({super.key});

  @override
  State<ShootPointsApp> createState() => _ShootPointsAppState();
}

class _ShootPointsAppState extends State<ShootPointsApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(context.read<FeedbackPromptProvider>().recordResumeIfDue());
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeModeController>();
    return MaterialApp(
      title: 'Point Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const LaunchScreen(),
    );
  }
}
