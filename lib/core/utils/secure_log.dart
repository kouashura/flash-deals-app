import 'package:flutter/foundation.dart';

/// Logger sécurisé qui masque les données sensibles en production
class SecureLog {
  static void d(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  static void i(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  static void e(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message ${error ?? ''}');
    }
  }

  /// Log un mot de passe masqué (JAMAIS en clair)
  static void password(String password) {
    if (kDebugMode) {
      final masked = '*' * password.length;
      debugPrint('[PASSWORD] $masked');
    }
  }
}
