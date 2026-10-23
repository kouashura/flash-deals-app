import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../domain/entities/order.dart';
import 'order_item_model.dart';
import 'delivery_model.dart';
import 'payment_model.dart';
import 'address_model.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.userId,
    required super.items,
    required super.address,
    required super.delivery,
    required super.payment,
    required super.subtotal,
    required super.total,
    required super.status,
    required super.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return OrderModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      items: itemsJson
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      address: AddressModel.fromJson(json['address'] as Map<String, dynamic>),
      delivery: DeliveryModel.fromJson(json['delivery'] as Map<String, dynamic>),
      payment: PaymentModel.fromJson(json['payment'] as Map<String, dynamic>),
      subtotal: (json['subtotal'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: (json['createdAt'] is Timestamp)
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'items': items.map((e) => (e as OrderItemModel).toJson()).toList(),
        'address': (address as AddressModel).toJson(),
        'delivery': (delivery as DeliveryModel).toJson(),
        'payment': (payment as PaymentModel).toJson(),
        'subtotal': subtotal,
        'total': total,
        'status': status.name,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
