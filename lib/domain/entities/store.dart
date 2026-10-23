import 'package:equatable/equatable.dart';

class Store extends Equatable {
  final String id;
  final String name;
  final String logoUrl;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final bool isOpen;

  const Store({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.rating = 0.0,
    this.isOpen = true,
  });

  @override
  List<Object?> get props => [id, name, address, latitude, longitude];
}
