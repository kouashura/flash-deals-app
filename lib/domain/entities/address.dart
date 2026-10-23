import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final String id;
  final String label;
  final String fullAddress;
  final String zone;
  final double latitude;
  final double longitude;
  final bool isDefault;

  const Address({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.zone,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
  });

  @override
  List<Object?> get props =>
      [id, label, fullAddress, zone, latitude, longitude];
}
