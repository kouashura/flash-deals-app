import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Service sécurisé pour l'authentification admin.
/// Le mot de passe n'est JAMAIS stocké en clair.
/// Seul son hash SHA-256 est présent dans le code.
class AdminAuthService {
  /// Hash SHA-256 du mot de passe admin.
  /// ⚠️ NE JAMAIS METTRE LE MOT DE PASSE EN CLAIR ICI.
  static const String _adminPasswordHash =
      'ca448a224299f6786153bc60829068fa458d16180816bb65ed524787abe5892a';

  /// Vérifie si le mot de passe est correct
  static bool verifyPassword(String input) {
    final inputHash = _hash(input);
    return _constantTimeEquals(inputHash, _adminPasswordHash);
  }

  /// Hash SHA-256
  static String _hash(String value) {
    final bytes = utf8.encode(value);
    return sha256.convert(bytes).toString();
  }

  /// Comparaison à temps constant (anti timing attacks)
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
