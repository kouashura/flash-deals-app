import 'package:equatable/equatable.dart';
import 'cart_item.dart';

class Cart extends Equatable {
  final List<CartItem> items;

  const Cart({this.items = const []});

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.lineTotal);

  double get totalSavings =>
      items.fold(0.0, (sum, item) => sum + item.lineSavings);

  int get totalItems =>
      items.fold(0, (sum, item) => sum + item.quantity);

  /// Poids total de la commande en kg
  double get totalWeightKg =>
      items.fold(0.0, (sum, item) => sum + (item.product.weightKg * item.quantity));

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  Cart copyWith({List<CartItem>? items}) =>
      Cart(items: items ?? this.items);

  @override
  List<Object?> get props => [items];
}
