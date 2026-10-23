#!/bin/bash
echo "🛒 Création du panier + checkout + paiement..."

# ============================================================
# CART BLOC — Event
# ============================================================
cat > lib/presentation/blocs/cart/cart_event.dart << 'DART'
import 'package:equatable/equatable.dart';
import '../../../domain/entities/product.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class AddToCart extends CartEvent {
  final Product product;
  final int quantity;

  const AddToCart(this.product, {this.quantity = 1});

  @override
  List<Object?> get props => [product, quantity];
}

class RemoveFromCart extends CartEvent {
  final String productId;

  const RemoveFromCart(this.productId);

  @override
  List<Object?> get props => [productId];
}

class UpdateQuantity extends CartEvent {
  final String productId;
  final int quantity;

  const UpdateQuantity(this.productId, this.quantity);

  @override
  List<Object?> get props => [productId, quantity];
}

class ClearCart extends CartEvent {
  const ClearCart();
}
DART

# ============================================================
# CART BLOC — State
# ============================================================
cat > lib/presentation/blocs/cart/cart_state.dart << 'DART'
import 'package:equatable/equatable.dart';
import '../../../domain/entities/cart.dart';

class CartState extends Equatable {
  final Cart cart;

  const CartState({this.cart = const Cart()});

  CartState copyWith({Cart? cart}) => CartState(cart: cart ?? this.cart);

  @override
  List<Object?> get props => [cart];
}
DART

# ============================================================
# CART BLOC — Bloc
# ============================================================
cat > lib/presentation/blocs/cart/cart_bloc.dart << 'DART'
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/cart_item.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddToCart>(_onAdd);
    on<RemoveFromCart>(_onRemove);
    on<UpdateQuantity>(_onUpdate);
    on<ClearCart>(_onClear);
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

    emit(state.copyWith(cart: Cart(items: currentItems)));
  }

  void _onRemove(RemoveFromCart event, Emitter<CartState> emit) {
    final currentItems = state.cart.items
        .where((item) => item.product.id != event.productId)
        .toList();
    emit(state.copyWith(cart: Cart(items: currentItems)));
  }

  void _onUpdate(UpdateQuantity event, Emitter<CartState> emit) {
    final currentItems = state.cart.items.map((item) {
      if (item.product.id == event.productId) {
        return item.copyWith(quantity: event.quantity);
      }
      return item;
    }).where((item) => item.quantity > 0).toList();

    emit(state.copyWith(cart: Cart(items: currentItems)));
  }

  void _onClear(ClearCart event, Emitter<CartState> emit) {
    emit(const CartState(cart: Cart()));
  }
}
DART

# ============================================================
# WIDGET: CART ITEM
# ============================================================
cat > lib/presentation/pages/cart/widgets/cart_item_tile.dart << 'DART'
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/cart_item.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.price(item.product.promoPrice),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  _qtyBtn(Icons.remove, () {
                    onQuantityChanged(item.quantity - 1);
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _qtyBtn(Icons.add, () {
                    onQuantityChanged(item.quantity + 1);
                  }),
                ],
              ),
              TextButton(
                onPressed: onRemove,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 24),
                ),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}
DART

# ============================================================
# PAGE: CART
# ============================================================
cat > lib/presentation/pages/cart/cart_page.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/delivery_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/cart/cart_state.dart';
import 'widgets/cart_item_tile.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mon panier')),
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

          final deliveryFee = DeliveryConstants.abidjanDeliveryFee;
          final subtotal = state.cart.subtotal;
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
            _row('Livraison Abidjan',
                Formatters.price(deliveryFee.toDouble())),
            const Divider(height: 20),
            _row('TOTAL', Formatters.price(total), bold: true),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.push('/checkout'),
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
DART

# ============================================================
# PAGE: CHECKOUT (position + livraison + paiement)
# ============================================================
cat > lib/presentation/pages/checkout/checkout_page.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/delivery_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_state.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedZone = DeliveryConstants.abidjanZones.first;
  String _selectedSlot = DeliveryConstants.timeSlots.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Finaliser la commande')),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          final subtotal = state.cart.subtotal;
          const deliveryFee = DeliveryConstants.abidjanDeliveryFee;
          final total = subtotal + deliveryFee;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // === POSITION ===
              _sectionTitle('📍 Ma position'),
              _card(
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.location_on, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Position GPS détectée',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '5.359952, -4.008256 • Cocody, Abidjan',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedZone,
                      decoration: const InputDecoration(
                        labelText: 'Zone de livraison',
                        border: OutlineInputBorder(),
                      ),
                      items: DeliveryConstants.abidjanZones
                          .map((z) => DropdownMenuItem(
                                value: z,
                                child: Text(z),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedZone = v ?? ''),
                    ),
                  ],
                ),
              ),

              // === CRÉNEAU ===
              _sectionTitle('🕒 Créneau de livraison'),
              _card(
                child: DropdownButtonFormField<String>(
                  value: _selectedSlot,
                  decoration: const InputDecoration(
                    labelText: 'Choisir un créneau',
                    border: OutlineInputBorder(),
                  ),
                  items: DeliveryConstants.timeSlots
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSlot = v ?? ''),
                ),
              ),

              // === FRAIS ===
              _sectionTitle('🚚 Frais de livraison'),
              _card(
                child: Row(
                  children: [
                    const Icon(Icons.delivery_dining,
                        color: AppColors.success, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Livraison partout à Abidjan',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      Formatters.price(deliveryFee.toDouble()),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // === RÉCAP ===
              _sectionTitle('🧾 Récapitulatif'),
              _card(
                child: Column(
                  children: [
                    _row('Sous-total', Formatters.price(subtotal)),
                    const SizedBox(height: 6),
                    _row('Livraison', Formatters.price(deliveryFee.toDouble())),
                    const Divider(height: 20),
                    _row('TOTAL', Formatters.price(total), bold: true),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.push('/payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Payer ${Formatters.price(total)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          t,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      );

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
DART

# ============================================================
# PAGE: PAYMENT METHODS
# ============================================================
cat > lib/presentation/pages/payment/payment_methods_page.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/payment.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  PaymentMethod _selected = PaymentMethod.orangeMoney;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Moyen de paiement')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _methodTile(PaymentMethod.orangeMoney, '🟠', 'Orange Money'),
          _methodTile(PaymentMethod.mtnMomo, '🟡', 'MTN Mobile Money'),
          _methodTile(PaymentMethod.moovMoney, '🔵', 'Moov Money'),
          _methodTile(PaymentMethod.wave, '🌊', 'Wave'),
          _methodTile(PaymentMethod.card, '💳', 'Carte bancaire'),
          _methodTile(PaymentMethod.wallet, '👛', 'Wallet Flash Deals'),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => context.push('/payment/mobile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continuer',
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
    );
  }

  Widget _methodTile(PaymentMethod m, String emoji, String label) {
    final selected = _selected == m;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: RadioListTile<PaymentMethod>(
        value: m,
        groupValue: _selected,
        onChanged: (v) => setState(() => _selected = v!),
        title: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      ),
    );
  }
}
DART

# ============================================================
# PAGE: MOBILE MONEY (simulation paiement)
# ============================================================
cat > lib/presentation/pages/payment/mobile_money_page.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/delivery_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/cart/cart_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileMoneyPage extends StatefulWidget {
  const MobileMoneyPage({super.key});

  @override
  State<MobileMoneyPage> createState() => _MobileMoneyPageState();
}

class _MobileMoneyPageState extends State<MobileMoneyPage> {
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _pay() async {
    if (_phoneCtrl.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro invalide')),
      );
      return;
    }

    setState(() => _loading = true);
    // Simulation de paiement (à remplacer par l'API réelle)
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    setState(() => _loading = false);

    context.read<CartBloc>().add(const ClearCart());
    context.go('/payment/success');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Paiement Mobile Money')),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          final total = state.cart.subtotal +
              DeliveryConstants.abidjanDeliveryFee;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  'Montant à payer',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  Formatters.price(total),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Numéro Mobile Money',
                    hintText: '+225 07 XX XX XX XX',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const CircularProgressIndicator()
                else
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _pay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Payer maintenant',
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
          );
        },
      ),
    );
  }
}
DART

# ============================================================
# PAGE: SUCCESS
# ============================================================
cat > lib/presentation/pages/payment/payment_success_page.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 80,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Commande confirmée !',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Votre livraison est en préparation.\nVous recevrez une notification.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Retour à l\'accueil',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
DART

echo "✅ Panier + checkout + paiement créés !"
