import 'package:equatable/equatable.dart';
import '../../../domain/entities/cart.dart';

class CartState extends Equatable {
  final Cart cart;

  const CartState({this.cart = const Cart()});

  CartState copyWith({Cart? cart}) => CartState(cart: cart ?? this.cart);

  @override
  List<Object?> get props => [cart];
}
