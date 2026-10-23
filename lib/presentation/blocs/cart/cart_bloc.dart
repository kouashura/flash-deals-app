import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/models/product_model.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/cart_item.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final StorageService _storage;

  CartBloc(this._storage) : super(const CartState()) {
    on<LoadCart>(_onLoad);
    on<AddToCart>(_onAdd);
    on<RemoveFromCart>(_onRemove);
    on<UpdateQuantity>(_onUpdate);
    on<ClearCart>(_onClear);
  }

  void _onLoad(LoadCart event, Emitter<CartState> emit) {
    final raw = _storage.loadCart();
    final items = raw.map((json) {
      return CartItemModel.fromJson(json);
    }).toList();
    emit(state.copyWith(cart: Cart(items: items)));
  }

  void _persist(List<CartItem> items) {
    final json = items.map((item) {
      return CartItemModel(
        product: item.product as ProductModel,
        quantity: item.quantity,
      ).toJson();
    }).toList();
    _storage.saveCart(json);
  }

  void _onAdd(AddToCart event, Emitter<CartState> emit) {
    final currentItems = List<CartItem>.from(state.cart.items);
    final index = currentItems.indexWhere(
      (item) => item.product.id == event.product.id,
    );

    if (index >= 0) {
      final existing = currentItems[index];
      currentItems[index] = existing.copyWith(
        quantity: existing.quantity + event.quantity,
      );
    } else {
      currentItems.add(CartItem(
        product: event.product,
        quantity: event.quantity,
      ));
    }

    _persist(currentItems);
    emit(state.copyWith(cart: Cart(items: currentItems)));
  }

  void _onRemove(RemoveFromCart event, Emitter<CartState> emit) {
    final currentItems = state.cart.items
        .where((item) => item.product.id != event.productId)
        .toList();
    _persist(currentItems);
    emit(state.copyWith(cart: Cart(items: currentItems)));
  }

  void _onUpdate(UpdateQuantity event, Emitter<CartState> emit) {
    final currentItems = state.cart.items
        .map((item) {
          if (item.product.id == event.productId) {
            return item.copyWith(quantity: event.quantity);
          }
          return item;
        })
        .where((item) => item.quantity > 0)
        .toList();

    _persist(currentItems);
    emit(state.copyWith(cart: Cart(items: currentItems)));
  }

  void _onClear(ClearCart event, Emitter<CartState> emit) {
    _storage.clearCart();
    emit(const CartState(cart: Cart()));
  }
}
