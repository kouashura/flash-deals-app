import 'package:equatable/equatable.dart';
import 'product.dart';

class OrderItem extends Equatable {
  final Product product;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });

  double get lineTotal => unitPrice * quantity;

  @override
  List<Object?> get props => [product, quantity, unitPrice];
}
