import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _languageKey = 'app_language';
  static const _notificationsKey = 'notifications_enabled';
  static const _dealAlertsKey = 'deal_alerts_enabled';
  static const _soundKey = 'sound_enabled';
  static const _biometricKey = 'biometric_enabled';
  static const _currencyKey = 'currency';

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  // ═══ LANGUE ═══
  static Future<String> getLanguage() async {
    final prefs = await _prefs;
    return prefs.getString(_languageKey) ?? 'fr';
  }

  static Future<void> setLanguage(String value) async {
    final prefs = await _prefs;
    await prefs.setString(_languageKey, value);
  }

  // ═══ NOTIFICATIONS ═══
  static Future<bool> getNotifications() async {
    final prefs = await _prefs;
    return prefs.getBool(_notificationsKey) ?? true;
  }

  static Future<void> setNotifications(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_notificationsKey, value);
  }

  static Future<bool> getDealAlerts() async {
    final prefs = await _prefs;
    return prefs.getBool(_dealAlertsKey) ?? true;
  }

  static Future<void> setDealAlerts(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_dealAlertsKey, value);
  }

  static Future<bool> getSound() async {
    final prefs = await _prefs;
    return prefs.getBool(_soundKey) ?? true;
  }

  static Future<void> setSound(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_soundKey, value);
  }

  // ═══ SÉCURITÉ ═══
  static Future<bool> getBiometric() async {
    final prefs = await _prefs;
    return prefs.getBool(_biometricKey) ?? false;
  }

  static Future<void> setBiometric(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_biometricKey, value);
  }

  // ═══ DEVISE ═══
  static Future<String> getCurrency() async {
    final prefs = await _prefs;
    return prefs.getString(_currencyKey) ?? 'FCFA';
  }

  static Future<void> setCurrency(String value) async {
    final prefs = await _prefs;
    await prefs.setString(_currencyKey, value);
  }
}
