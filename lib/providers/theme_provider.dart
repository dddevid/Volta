import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
    _initHighRefreshRate();
  }

  Future<void> _initHighRefreshRate() async {
    try {
      // Get available modes
      final List<DisplayMode> modes = await FlutterDisplayMode.supported;

      // Find the mode with highest refresh rate
      DisplayMode? preferred = modes.isNotEmpty
          ? modes.reduce((a, b) => a.refreshRate > b.refreshRate ? a : b)
          : null;

      if (preferred != null) {
        await FlutterDisplayMode.setPreferredMode(preferred);
        print('Set display mode to ${preferred.refreshRate}Hz');
      }
    } catch (e) {
      // Ignore errors on platforms that don't support this
      print('Could not set high refresh rate: $e');
    }
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('themeMode');
    if (savedMode != null) {
      if (savedMode == 'light') {
        _themeMode = ThemeMode.light;
      } else if (savedMode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    String value = 'system';
    if (mode == ThemeMode.light) value = 'light';
    if (mode == ThemeMode.dark) value = 'dark';
    await prefs.setString('themeMode', value);
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}
