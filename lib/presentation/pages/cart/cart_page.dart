import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/cart/cart_state.dart';
import '../../blocs/delivery/delivery_bloc.dart';
import '../../blocs/delivery/delivery_event.dart';
import '../../blocs/delivery/delivery_state.dart';
import '../../widgets/snackbars/app_snackbar.dart';
import 'widgets/cart_item_tile.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cart = context.read<CartBloc>().state.cart;
      context
          .read<DeliveryBloc>()
          .add(RecalculateDelivery(cart.totalWeightKg));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon panier'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.cart.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Votre panier est vide'),
                ],
              ),
            );
          }

          final subtotal = state.cart.subtotal;

          return BlocBuilder<DeliveryBloc, DeliveryState>(
            builder: (context, delState) {
              final deliveryFee = delState.currentFee;
              final total = subtotal + deliveryFee;

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.cart.items.length,
                      itemBuilder: (context, i) {
                        final item = state.cart.items[i];
                        return CartItemTile(
                          item: item,
                          onRemove: () {
                            context
                                .read<CartBloc>()
                                .add(RemoveFromCart(item.product.id));
                          },
                          onQuantityChanged: (q) {
                            context
                                .read<CartBloc>()
                                .add(UpdateQuantity(item.product.id, q));
                          },
                        );
                      },
                    ),
                  ),
                  _buildSummary(context, subtotal, deliveryFee, total),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummary(
    BuildContext context,
    double subtotal,
    int deliveryFee,
    double total,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            _row('Sous-total', Formatters.price(subtotal)),
            const SizedBox(height: 6),
            _row('Livraison estimée',
                Formatters.price(deliveryFee.toDouble())),
            const Divider(height: 20),
            _row('TOTAL', Formatters.price(total), bold: true),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (FirebaseAuth.instance.currentUser == null) {
                    AppSnackbar.warning(
                        context, 'Connectez-vous pour passer commande');
                    context.push('/login');
                    return;
                  }
                  context.push('/checkout');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Passer la commande',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontSize: bold ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            fontSize: bold ? 16 : 14,
            color: bold ? AppColors.primary : Colors.black87,
          ),
        ),
      ],
    );
  }
}
