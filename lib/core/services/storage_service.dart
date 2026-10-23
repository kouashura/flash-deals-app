import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _cartKey = 'cart_items';
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ============ CART ============
  Future<void> saveCart(List<Map<String, dynamic>> items) async {
    await _prefs.setString(_cartKey, jsonEncode(items));
  }

  List<Map<String, dynamic>> loadCart() {
    final raw = _prefs.getString(_cartKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> clearCart() async {
    await _prefs.remove(_cartKey);
  }

  // ============ USER ============
  Future<void> saveUser(Map<String, dynamic> user) async {
    await _prefs.setString(_userKey, jsonEncode(user));
  }

  Map<String, dynamic>? loadUser() {
    final raw = _prefs.getString(_userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clearUser() async {
    await _prefs.remove(_userKey);
  }

  // ============ TOKEN ============
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  String? loadToken() => _prefs.getString(_tokenKey);

  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
