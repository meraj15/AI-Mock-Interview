import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

class ThemeController extends ChangeNotifier {
  final SharedPreferences sharedPreferences;
  static const String keyTheme = 'interview-coach-theme';

  AppThemeMode _themeMode = AppThemeMode.system;

  AppThemeMode get themeMode => _themeMode;

  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  ThemeController({required this.sharedPreferences}) {
    _loadTheme();
  }

  void _loadTheme() {
    final stored = sharedPreferences.getString(keyTheme);
    if (stored == 'light') {
      _themeMode = AppThemeMode.light;
    } else if (stored == 'dark') {
      _themeMode = AppThemeMode.dark;
    } else {
      _themeMode = AppThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    String str = 'system';
    if (mode == AppThemeMode.light) str = 'light';
    if (mode == AppThemeMode.dark) str = 'dark';
    await sharedPreferences.setString(keyTheme, str);
  }
}
