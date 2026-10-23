import 'package:equatable/equatable.dart';

abstract class DeliveryEvent extends Equatable {
  const DeliveryEvent();
  @override
  List<Object?> get props => [];
}

/// Changer de mode de livraison
class SetDeliveryMode extends DeliveryEvent {
  final DeliveryMode mode;
  const SetDeliveryMode(this.mode);
  @override
  List<Object?> get props => [mode];
}

/// Changer de zone
class SetDeliveryZone extends DeliveryEvent {
  final String zone;
  const SetDeliveryZone(this.zone);
  @override
  List<Object?> get props => [zone];
}

/// Recalculer les frais
class RecalculateDelivery extends DeliveryEvent {
  final double totalWeightKg;
  const RecalculateDelivery(this.totalWeightKg);
  @override
  List<Object?> get props => [totalWeightKg];
}

enum DeliveryMode { delivery, pickup }
