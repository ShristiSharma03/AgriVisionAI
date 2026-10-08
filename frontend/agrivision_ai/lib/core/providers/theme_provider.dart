import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app's light/dark mode preference.
///
/// Wrap the app root with ChangeNotifierProvider<ThemeProvider> (see
/// main.dart), then read it anywhere with:
///   context.watch<ThemeProvider>().themeMode   // to rebuild on change
///   context.read<ThemeProvider>().toggleTheme() // to change it
class ThemeProvider extends ChangeNotifier {
  static const _prefsKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == 'dark') {
      _themeMode = ThemeMode.dark;
      notifyListeners();
    } else if (saved == 'light') {
      _themeMode = ThemeMode.light;
      notifyListeners();
    }
    // If nothing saved yet, keep the default (light) — matches the
    // Settings screen design, which defaults to "Light" selected.
  }

  Future<void> setTheme(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> toggleTheme() async {
    await setTheme(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}