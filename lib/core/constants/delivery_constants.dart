class DeliveryConstants {
  /// Frais de livraison fixes pour Abidjan (FCFA)
  static const int abidjanDeliveryFee = 1500;

  /// Devise
  static const String currency = 'FCFA';

  /// Zones couvertes (à étendre)
  static const List<String> abidjanZones = [
    'Cocody',
    'Plateau',
    'Yopougon',
    'Adjamé',
    'Abobo',
    'Treichville',
    'Marcory',
    'Koumassi',
    'Port-Bouët',
    'Bingerville',
    'Riviera',
    'Angré',
  ];

  /// Créneaux horaires
  static const List<String> timeSlots = [
    '08h - 10h',
    '10h - 12h',
    '12h - 14h',
    '14h - 16h',
    '16h - 18h',
    '18h - 20h',
  ];
}
