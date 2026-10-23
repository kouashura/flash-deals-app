import 'package:equatable/equatable.dart';

enum DeliveryStatus {
  pending,      // En attente
  confirmed,    // Confirmée
  preparing,    // En préparation (magasin)
  onTheWay,     // En cours de livraison
  delivered,    // Livré
  cancelled,    // Annulée
}

extension DeliveryStatusX on DeliveryStatus {
  String get label {
    switch (this) {
      case DeliveryStatus.pending:
        return 'En attente';
      case DeliveryStatus.confirmed:
        return 'Confirmée';
      case DeliveryStatus.preparing:
        return 'En préparation';
      case DeliveryStatus.onTheWay:
        return 'En cours de livraison';
      case DeliveryStatus.delivered:
        return 'Livré';
      case DeliveryStatus.cancelled:
        return 'Annulée';
    }
  }
}

class Delivery extends Equatable {
  final String id;
  final String addressId;
  final String zone;
  final double latitude;
  final double longitude;
  final int fee;              // en FCFA (fixe = 1500 pour Abidjan)
  final String timeSlot;
  final DeliveryStatus status;
  final String? trackingCode;

  const Delivery({
    required this.id,
    required this.addressId,
    required this.zone,
    required this.latitude,
    required this.longitude,
    required this.fee,
    required this.timeSlot,
    this.status = DeliveryStatus.pending,
    this.trackingCode,
  });

  @override
  List<Object?> get props => [id, zone, fee, status];
}
