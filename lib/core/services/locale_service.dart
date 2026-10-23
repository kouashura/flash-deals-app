import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
  static const _key = 'app_language';

  Locale _locale = const Locale('fr');
  Locale get locale => _locale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_key) ?? 'fr';
    _locale = Locale(lang);
    notifyListeners();
  }

  Future<void> setLocale(String code) async {
    _locale = Locale(code);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }
}
