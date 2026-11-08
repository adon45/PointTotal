import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeController extends ChangeNotifier {
  static const _storageKey = 'point_tracker_dark_mode';

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _isDarkMode = preferences.getBool(_storageKey) ?? false;
  }

  Future<void> toggle() async {
    final nextValue = !_isDarkMode;
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(_storageKey, nextValue);
    if (!saved) {
      throw StateError('Could not save the color scheme preference.');
    }
    _isDarkMode = nextValue;
    notifyListeners();
  }
}
