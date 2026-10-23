import '../../domain/entities/delivery.dart';
import '../../core/constants/delivery_constants.dart';

class DeliveryModel extends Delivery {
  const DeliveryModel({
    required super.id,
    required super.addressId,
    required super.zone,
    required super.latitude,
    required super.longitude,
    required super.fee,
    required super.timeSlot,
    required super.status,
    super.trackingCode,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id: json['id'] as String,
      addressId: json['addressId'] as String,
      zone: json['zone'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      fee: json['fee'] as int? ?? DeliveryConstants.abidjanDeliveryFee,
      timeSlot: json['timeSlot'] as String,
      status: DeliveryStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DeliveryStatus.pending,
      ),
      trackingCode: json['trackingCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'addressId': addressId,
        'zone': zone,
        'latitude': latitude,
        'longitude': longitude,
        'fee': fee,
        'timeSlot': timeSlot,
        'status': status.name,
        'trackingCode': trackingCode,
      };
}
