import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service qui gère le thème (clair/sombre) + persistance
class ThemeService extends ChangeNotifier {
  static const String _key = 'dark_mode';

  bool _isDark = false;
  bool get isDark => _isDark;

  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  /// Charge la préférence au démarrage
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  /// Active/désactive le mode sombre
  Future<void> toggle(bool value) async {
    _isDark = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
