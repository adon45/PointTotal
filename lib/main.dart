import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/launch_screen.dart';
import 'state/entries_provider.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final entriesProvider = EntriesProvider();
  final themeModeController = ThemeModeController();
  await entriesProvider.load();
  await themeModeController.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: entriesProvider),
        ChangeNotifierProvider.value(value: themeModeController),
      ],
      child: const ShootPointsApp(),
    ),
  );
}

class ShootPointsApp extends StatelessWidget {
  const ShootPointsApp({super.key});

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
