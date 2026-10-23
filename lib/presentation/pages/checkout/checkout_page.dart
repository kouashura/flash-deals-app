import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/delivery_pricing_service.dart';
import '../../../core/utils/formatters.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_state.dart';
import '../../blocs/delivery/delivery_bloc.dart';
import '../../blocs/delivery/delivery_event.dart';
import '../../blocs/delivery/delivery_state.dart';
import 'address_input_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedSlot = '08h - 10h';

  // === ADRESSE CLIENT ===
  String? _address;
  String? _phone;
  double? _latitude;
  double? _longitude;

  static const _timeSlots = [
    '08h - 10h',
    '10h - 12h',
    '12h - 14h',
    '14h - 16h',
    '16h - 18h',
    '18h - 20h',
  ];

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
      appBar: AppBar(title: const Text('Finaliser la commande')),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          final cart = cartState.cart;
          final subtotal = cart.subtotal;
          final weight = cart.totalWeightKg;

          return BlocBuilder<DeliveryBloc, DeliveryState>(
            builder: (context, delState) {
              final deliveryFee = delState.currentFee;
              final total = subtotal + deliveryFee;
              final canPay = delState.error == null &&
                  (delState.mode == DeliveryMode.pickup ||
                      (_address != null && _phone != null));

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // === RÉCAP COMMANDE ===
                  _sectionTitle('📦 Ma commande'),
                  _card(
                    child: Column(
                      children: [
                        _infoRow('Articles', '${cart.totalItems}'),
                        const SizedBox(height: 6),
                        _infoRow(
                          'Poids total',
                          '${weight.toStringAsFixed(2)} kg',
                        ),
                      ],
                    ),
                  ),

                  // === MODE DE RÉCEPTION ===
                  _sectionTitle('🚚 Mode de réception'),
                  _buildModeSelector(delState),

                  // === SI LIVRAISON : ADRESSE + ZONE ===
                  if (delState.mode == DeliveryMode.delivery) ...[
                    _sectionTitle('📍 Mon adresse'),
                    _buildAddressCard(),

                    if (_address != null) ...[
                      _sectionTitle('🗺️ Zone de livraison'),
                      _buildZoneSelector(delState),
                    ],

                    if (delState.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            delState.error!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    else if (_address != null)
                      _buildDeliveryBreakdown(delState),

                    _sectionTitle('🕒 Créneau de livraison'),
                    _card(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSlot,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: _timeSlots
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedSlot = v ?? ''),
                      ),
                    ),
                  ],

                  // === SI RÉCUPÉRATION ===
                  if (delState.mode == DeliveryMode.pickup)
                    _buildPickupInfo(delState),

                  // === RÉCAPITULATIF FINAL ===
                  _sectionTitle('🧾 Récapitulatif'),
                  _card(
                    child: Column(
                      children: [
                        _infoRow('Sous-total', Formatters.price(subtotal)),
                        const SizedBox(height: 6),
                        if (delState.mode == DeliveryMode.delivery)
                          _infoRow(
                            'Livraison (${delState.zone})',
                            Formatters.price(deliveryFee.toDouble()),
                          )
                        else
                          _infoRow(
                            'Frais de récupération',
                            Formatters.price(deliveryFee.toDouble()),
                          ),
                        const Divider(height: 20),
                        _infoRow(
                          'TOTAL À PAYER',
                          Formatters.price(total),
                          bold: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // === BOUTON PAYER ===
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: canPay
                          ? () => context.push('/payment', extra: {
                            'total': total,
                            'phone': _phone ?? '',
                            'address': _address ?? '',
                            'deliveryFee': delState.currentFee,
                            'zone': delState.zone,
                            'timeSlot': _selectedSlot,
                          })
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        canPay
                            ? 'Payer ${Formatters.price(total)}'
                            : 'Renseignez votre adresse',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  // Message d'aide si adresse manquante
                  if (delState.mode == DeliveryMode.delivery &&
                      (_address == null || _phone == null)) ...[
                    const SizedBox(height: 8),
                    const Text(
                      '⚠️ Cliquez sur "Mon adresse" pour renseigner votre adresse et votre numéro.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ============= ADRESSE =============
  Widget _buildAddressCard() {
    return _card(
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddressInputPage(
                initialAddress: _address,
              ),
            ),
          );
          if (result != null) {
            setState(() {
              _address = result['address'];
              _phone = result['phone'];
              _latitude = result['latitude'];
              _longitude = result['longitude'];
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _address ?? 'Cliquez pour saisir votre adresse',
                      style: TextStyle(
                        fontWeight: _address != null
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _address != null
                            ? Colors.black87
                            : Colors.grey,
                      ),
                    ),
                    if (_phone != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '📞 $_phone',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    if (_latitude != null && _longitude != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '🗺️ GPS: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ============= MODE SELECTOR =============
  Widget _buildModeSelector(DeliveryState state) {
    return Row(
      children: [
        Expanded(
          child: _modeCard(
            state: state,
            mode: DeliveryMode.delivery,
            icon: Icons.delivery_dining,
            title: 'Livraison',
            subtitle: 'À votre adresse',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _modeCard(
            state: state,
            mode: DeliveryMode.pickup,
            icon: Icons.store,
            title: 'Récupérer',
            subtitle: '${DeliveryPricingService.pickupFee} FCFA fixe',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _modeCard({
    required DeliveryState state,
    required DeliveryMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = state.mode == mode;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.read<DeliveryBloc>().add(SetDeliveryMode(mode)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? color : Colors.grey, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============= ZONE =============
  Widget _buildZoneSelector(DeliveryState state) {
    return _card(
      child: DropdownButtonFormField<String>(
        value: state.zone,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.location_on, color: AppColors.primary),
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: DeliveryPricingService.availableZones.map((zone) {
          final fee = DeliveryPricingService.zones[zone]?.baseFee ?? 0;
          return DropdownMenuItem(
            value: zone,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(zone),
                Text(
                  '~$fee F',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) {
            context.read<DeliveryBloc>().add(SetDeliveryZone(v));
          }
        },
      ),
    );
  }

  // ============= DÉTAIL CALCUL =============
  Widget _buildDeliveryBreakdown(DeliveryState state) {
    final breakdown = DeliveryPricingService.getFeeBreakdown(
      totalWeightKg: state.totalWeightKg,
      zone: state.zone,
    );

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calculate, color: AppColors.primary, size: 18),
              SizedBox(width: 6),
              Text(
                'Détail du calcul',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow('Frais de base', '${breakdown['baseFee']} F'),
          if ((breakdown['extraFee'] as int) > 0)
            _infoRow(
              'Poids sup. (${(breakdown['extraWeight'] as double).toStringAsFixed(1)} kg)',
              '+${breakdown['extraFee']} F',
            ),
          const Divider(height: 16),
          _infoRow('Total livraison', '${breakdown['total']} F',
              bold: true),
        ],
      ),
    );
  }

  // ============= INFOS RÉCUPÉRATION =============
  Widget _buildPickupInfo(DeliveryState state) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.success),
              SizedBox(width: 8),
              Text(
                'Mode Récupération',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Vous récupérez votre commande directement dans nos entrepôts partenaires. Des frais de préparation de 1 000 FCFA s\'appliquent.',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          const Text(
            '📍 Point de retrait : Entrepôt central, Zone 4, Abidjan',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  // ============= HELPERS =============
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

  Widget _infoRow(String label, String value, {bool bold = false}) {
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
