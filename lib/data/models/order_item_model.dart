import '../../domain/entities/order_item.dart';
import 'product_model.dart';

class OrderItemModel extends OrderItem {
  const OrderItemModel({
    required super.product,
    required super.quantity,
    required super.unitPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'product': (product as ProductModel).toJson(),
        'quantity': quantity,
        'unitPrice': unitPrice,
      };
}
