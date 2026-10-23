import 'package:equatable/equatable.dart';
import 'product.dart';

class CartItem extends Equatable {
  final Product product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  double get lineTotal => product.promoPrice * quantity;
  double get lineTotalNormal => product.normalPrice * quantity;
  double get lineSavings => lineTotalNormal - lineTotal;

  CartItem copyWith({int? quantity}) => CartItem(
        product: product,
        quantity: quantity ?? this.quantity,
      );

  @override
  List<Object?> get props => [product, quantity];
}
