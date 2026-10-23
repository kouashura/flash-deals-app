import '../constants/delivery_constants.dart';

class DeliveryService {
  /// Retourne les frais de livraison (fixe pour Abidjan)
  int calculateFee({required String zone}) {
    if (DeliveryConstants.abidjanZones.contains(zone)) {
      return DeliveryConstants.abidjanDeliveryFee;
    }
    throw Exception('Zone non couverte : $zone');
  }

  bool isZoneCovered(String zone) =>
      DeliveryConstants.abidjanZones.contains(zone);
}
