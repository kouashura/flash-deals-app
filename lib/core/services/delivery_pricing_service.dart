/// Service professionnel de calcul des frais de livraison
/// Basé sur le poids total + la zone géographique
class DeliveryPricingService {
  // Frais fixes pour la récupération
  static const int pickupFee = 1000;

  // Poids minimum facturé (kg)
  static const double minBillableWeight = 5.0;

  // Poids maximum par commande (kg)
  static const double maxWeight = 50.0;

  /// Grille tarifaire par zone
  /// [baseFee] : frais de base quelle que soit la quantité
  /// [perKgBeyondMin] : tarif par kg au-delà de 5 kg
  static final Map<String, ZonePricing> zones = {
    // Zone 1 : Centre / Proche
    'Cocody': ZonePricing(baseFee: 800, perKgBeyondMin: 150),
    'Plateau': ZonePricing(baseFee: 800, perKgBeyondMin: 150),
    'Adjamé': ZonePricing(baseFee: 800, perKgBeyondMin: 150),
    
    // Zone 2 : Périphérie Ouest / Nord
    'Yopougon': ZonePricing(baseFee: 1200, perKgBeyondMin: 200),
    'Abobo': ZonePricing(baseFee: 1200, perKgBeyondMin: 200),
    'Treichville': ZonePricing(baseFee: 1200, perKgBeyondMin: 200),
    
    // Zone 3 : Sud
    'Marcory': ZonePricing(baseFee: 1000, perKgBeyondMin: 180),
    'Koumassi': ZonePricing(baseFee: 1000, perKgBeyondMin: 180),
    'Port-Bouët': ZonePricing(baseFee: 1000, perKgBeyondMin: 180),
    
    // Zone 4 : Est / Éloigné
    'Bingerville': ZonePricing(baseFee: 1500, perKgBeyondMin: 250),
    'Riviera': ZonePricing(baseFee: 1500, perKgBeyondMin: 250),
    'Angré': ZonePricing(baseFee: 1500, perKgBeyondMin: 250),
  };

  /// Calcule les frais de livraison selon le poids et la zone
  /// 
  /// [totalWeightKg] : poids total des articles en kilogrammes
  /// [zone] : nom de la zone de livraison
  /// 
  /// Retourne les frais en FCFA
  static int calculateDeliveryFee({
    required double totalWeightKg,
    required String zone,
  }) {
    final pricing = zones[zone];
    if (pricing == null) {
      throw DeliveryPricingException('Zone non couverte : $zone');
    }

    // Vérifier le poids max
    if (totalWeightKg > maxWeight) {
      throw DeliveryPricingException(
        'Poids maximum dépassé ($maxWeight kg). '
        'Veuillez contacter le support pour les commandes volumineuses.',
      );
    }

    // Frais de base
    int fee = pricing.baseFee;

    // Si le poids dépasse 5 kg, ajouter le tarif au kg
    if (totalWeightKg > minBillableWeight) {
      final extraWeight = totalWeightKg - minBillableWeight;
      final extraFee = (extraWeight * pricing.perKgBeyondMin).round();
      fee += extraFee;
    }

    return fee;
  }

  /// Retourne les frais de récupération (fixes)
  static int calculatePickupFee() => pickupFee;

  /// Vérifie si une zone est couverte
  static bool isZoneCovered(String zone) => zones.containsKey(zone);

  /// Retourne la liste des zones couvertes
  static List<String> get availableZones => zones.keys.toList();

  /// Détails pour débug / affichage
  static Map<String, dynamic> getFeeBreakdown({
    required double totalWeightKg,
    required String zone,
  }) {
    final pricing = zones[zone];
    if (pricing == null) {
      return {'error': 'Zone non couverte'};
    }

    final extraWeight = totalWeightKg > minBillableWeight
        ? totalWeightKg - minBillableWeight
        : 0.0;
    final extraFee = (extraWeight * pricing.perKgBeyondMin).round();

    return {
      'zone': zone,
      'baseFee': pricing.baseFee,
      'weight': totalWeightKg,
      'extraWeight': extraWeight,
      'extraFee': extraFee,
      'total': pricing.baseFee + extraFee,
    };
  }
}

class ZonePricing {
  final int baseFee;
  final int perKgBeyondMin;

  const ZonePricing({
    required this.baseFee,
    required this.perKgBeyondMin,
  });
}

class DeliveryPricingException implements Exception {
  final String message;
  DeliveryPricingException(this.message);

  @override
  String toString() => message;
}
