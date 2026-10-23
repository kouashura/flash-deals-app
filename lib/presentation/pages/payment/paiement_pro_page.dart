import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/payment/paiement_pro_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/address_model.dart';
import '../../../data/models/delivery_model.dart';
import '../../../data/models/order_item_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../domain/entities/delivery.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/payment.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/cart/cart_state.dart';
import '../../widgets/snackbars/app_snackbar.dart';

class PaiementProPage extends StatefulWidget {
  final String channel;
  final String channelLabel;
  final String? phone;
  final String? address;
  final int? deliveryFee;
  final String? zone;
  final String? timeSlot;

  const PaiementProPage({
    super.key,
    required this.channel,
    required this.channelLabel,
    this.phone,
    this.address,
    this.deliveryFee,
    this.zone,
    this.timeSlot,
  });

  @override
  State<PaiementProPage> createState() => _PaiementProPageState();
}

class _PaiementProPageState extends State<PaiementProPage> {
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  int get _deliveryFee => widget.deliveryFee ?? 1500;

  @override
  void initState() {
    super.initState();
    if (widget.phone != null && widget.phone!.isNotEmpty) {
      _phoneCtrl.text = widget.phone!;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      _emailCtrl.text = user.email!;
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _startPayment() async {
    if (_phoneCtrl.text.length < 8) {
      AppSnackbar.warning(context, 'Numéro invalide');
      return;
    }
    if (_emailCtrl.text.isEmpty || !_emailCtrl.text.contains('@')) {
      AppSnackbar.warning(context, 'Email invalide');
      return;
    }

    final cart = context.read<CartBloc>().state.cart;
    if (cart.isEmpty) {
      AppSnackbar.error(context, 'Panier vide');
      return;
    }

    setState(() => _loading = true);

    final total = cart.subtotal + _deliveryFee;
    final reference = PaiementProService.generateReference();

    if (!mounted) return;
    setState(() => _loading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaiementProWebView(
          amount: total,
          channel: widget.channel == 'ALL' ? 'WAVE' : widget.channel,
          referenceNumber: reference,
          customerEmail: _emailCtrl.text.trim(),
          customerFirstName: 'Client',
          customerLastName: 'Flash Deals',
          customerPhone: _phoneCtrl.text.trim(),
          description: 'Commande Flash Deals - ${cart.totalItems} articles',
          returnURL: 'https://flashdeals-abidjan.web.app/payment_return',
          notificationURL:
              'https://flashdeals-abidjan.web.app/payment_notify',
          onSuccess: () => _onPaymentSuccess(reference, total),
          onFailure: () => _onPaymentFailure(),
        ),
      ),
    );
  }

  Future<void> _onPaymentSuccess(String reference, double total) async {
    try {
      final cart = context.read<CartBloc>().state.cart;

      final order = OrderModel(
        id: '',
        userId: '',
        items: cart.items
            .map((item) => OrderItemModel(
                  product: item.product,
                  quantity: item.quantity,
                  unitPrice: item.product.promoPrice,
                ))
            .toList(),
        address: AddressModel(
          id: 'a1',
          label: 'Domicile',
          fullAddress: widget.address ?? 'Adresse client',
          zone: widget.zone ?? 'Cocody',
          latitude: 5.359952,
          longitude: -4.008256,
        ),
        delivery: DeliveryModel(
          id: 'd1',
          addressId: 'a1',
          zone: widget.zone ?? 'Cocody',
          latitude: 5.359952,
          longitude: -4.008256,
          fee: _deliveryFee,
          timeSlot: widget.timeSlot ?? '08h - 10h',
          status: DeliveryStatus.pending,
        ),
        payment: PaymentModel(
          id: reference,
          method: PaymentMethod.card,
          amount: total,
          status: PaymentStatus.success,
        ),
        subtotal: cart.subtotal,
        total: total,
        status: OrderStatus.confirmed,
        createdAt: DateTime.now(),
      );

      final orderId = await OrderService().createOrder(order);

      if (mounted) {
        context.read<CartBloc>().add(const ClearCart());
        context.go('/payment/success?orderId=$orderId');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Erreur : $e');
      }
    }
  }

  void _onPaymentFailure() {
    if (mounted) {
      AppSnackbar.error(context, 'Paiement annulé ou échoué');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paiement sécurisé'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          final subtotal = state.cart.subtotal;
          final total = subtotal + _deliveryFee;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Détail du montant
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFFFF9800)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Total à payer',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          Formatters.price(total),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            _summaryRow('Sous-total',
                                Formatters.price(subtotal)),
                            const SizedBox(height: 4),
                            _summaryRow(
                              'Livraison${widget.zone != null ? ' (${widget.zone})' : ''}',
                              Formatters.price(_deliveryFee.toDouble()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.primary, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Sur la page suivante, choisissez votre opérateur (Wave, Orange, MTN, Moov) ou payez par carte.',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  '📞 Numéro de téléphone',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '+225 07 XX XX XX XX',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  '📧 Email',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'client@email.com',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _startPayment,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.payment, color: Colors.white),
                    label: Text(
                      _loading
                          ? 'Chargement...'
                          : 'Payer ${Formatters.price(total)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
