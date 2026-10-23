import '../../domain/entities/cart.dart';
import 'cart_item_model.dart';

class CartModel extends Cart {
  const CartModel({required super.items});

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return CartModel(
      items: itemsJson
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items
            .map((e) => (e as CartItemModel).toJson())
            .toList(),
      };
}
