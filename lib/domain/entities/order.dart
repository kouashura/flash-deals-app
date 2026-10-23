import 'package:equatable/equatable.dart';
import 'order_item.dart';
import 'delivery.dart';
import 'payment.dart';
import 'address.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  onTheWay,
  delivered,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.confirmed:
        return 'Confirmée';
      case OrderStatus.preparing:
        return 'En préparation';
      case OrderStatus.onTheWay:
        return 'En route';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.cancelled:
        return 'Annulée';
    }
  }
}

class Order extends Equatable {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final Address address;
  final Delivery delivery;
  final Payment payment;
  final double subtotal;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.address,
    required this.delivery,
    required this.payment,
    required this.subtotal,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  int get totalItems =>
      items.fold(0, (sum, item) => sum + item.quantity);

  @override
  List<Object?> get props => [id, status, total, createdAt];
}
