import 'package:equatable/equatable.dart';

/// Statut de vérification du livreur
enum CourierStatus {
  pending,    // En attente de validation
  approved,   // Validé par admin
  rejected,   // Refusé
  suspended,  // Suspendu
}

extension CourierStatusX on CourierStatus {
  String get label {
    switch (this) {
      case CourierStatus.pending:
        return 'En attente de validation';
      case CourierStatus.approved:
        return 'Validé';
      case CourierStatus.rejected:
        return 'Refusé';
      case CourierStatus.suspended:
        return 'Suspendu';
    }
  }
}

/// Type de véhicule
enum VehicleType {
  motorcycle,  // Moto
  bicycle,     // Vélo
  car,         // Voiture
  scooter,     // Scooter
}

extension VehicleTypeX on VehicleType {
  String get label {
    switch (this) {
      case VehicleType.motorcycle:
        return 'Moto';
      case VehicleType.bicycle:
        return 'Vélo';
      case VehicleType.car:
        return 'Voiture';
      case VehicleType.scooter:
        return 'Scooter';
    }
  }
}

class Courier extends Equatable {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String city;
  final String zone;
  final String address;
  final VehicleType vehicleType;
  final String vehiclePlate;
  final String idCardNumber;      // N° CNI
  final String? idCardUrl;         // Photo CNI
  final String? photoUrl;          // Photo de profil
  final String? licenseUrl;        // Photo permis (si véhicule motorisé)
  final CourierStatus status;
  final bool isAvailable;          // Disponible pour livrer
  final int totalDeliveries;
  final double totalEarnings;
  final double rating;
  final DateTime createdAt;
  final DateTime? approvedAt;

  const Courier({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.city,
    required this.zone,
    required this.address,
    required this.vehicleType,
    required this.vehiclePlate,
    required this.idCardNumber,
    this.idCardUrl,
    this.photoUrl,
    this.licenseUrl,
    this.status = CourierStatus.pending,
    this.isAvailable = false,
    this.totalDeliveries = 0,
    this.totalEarnings = 0,
    this.rating = 0,
    required this.createdAt,
    this.approvedAt,
  });

  @override
  List<Object?> get props => [id, fullName, phone, status];
}
