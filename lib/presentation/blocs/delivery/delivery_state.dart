import 'package:equatable/equatable.dart';
import 'delivery_event.dart';

class DeliveryState extends Equatable {
  final DeliveryMode mode;
  final String zone;
  final double totalWeightKg;
  final int deliveryFee;
  final int pickupFee;
  final String? error;

  const DeliveryState({
    this.mode = DeliveryMode.delivery,
    this.zone = 'Cocody',
    this.totalWeightKg = 0.0,
    this.deliveryFee = 0,
    this.pickupFee = 1000,
    this.error,
  });

  /// Frais effectifs selon le mode choisi
  int get currentFee => mode == DeliveryMode.delivery ? deliveryFee : pickupFee;

  /// Le mode récupération ?
  bool get isPickup => mode == DeliveryMode.pickup;

  DeliveryState copyWith({
    DeliveryMode? mode,
    String? zone,
    double? totalWeightKg,
    int? deliveryFee,
    int? pickupFee,
    String? error,
    bool clearError = false,
  }) {
    return DeliveryState(
      mode: mode ?? this.mode,
      zone: zone ?? this.zone,
      totalWeightKg: totalWeightKg ?? this.totalWeightKg,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      pickupFee: pickupFee ?? this.pickupFee,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [mode, zone, totalWeightKg, deliveryFee, pickupFee, error];
}
