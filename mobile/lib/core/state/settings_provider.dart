import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  // Distance radius in km (user-configurable, default 5 km)
  double _radiusKm = 5.0;
  double get radiusKm => _radiusKm;

  void setRadiusKm(double value) {
    _radiusKm = value.clamp(1.0, 50.0);
    notifyListeners();
  }

  // Theme mode (dark by default to match existing app)
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
