class Validators {
  static String? email(String? v) {
    if (v == null || v.isEmpty) return 'Email requis';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Email invalide';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.isEmpty) return 'Téléphone requis';
    if (v.length < 8) return 'Téléphone invalide';
    return null;
  }

  static String? required(String? v, [String field = 'Champ']) {
    if (v == null || v.isEmpty) return '$field requis';
    return null;
  }
}
