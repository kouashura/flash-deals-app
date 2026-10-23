import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/payment.dart';

class PaymentMethodsPage extends StatefulWidget {
  final double total;
  const PaymentMethodsPage({super.key, required this.total});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  PaymentMethod _selected = PaymentMethod.orangeMoney;

  /// Groupes de méthodes
  static const _mobileMoney = [
    _PaymentOption(
      method: PaymentMethod.orangeMoney,
      label: 'Orange Money',
      emoji: '🟠',
      color: Color(0xFFFF7900),
    ),
    _PaymentOption(
      method: PaymentMethod.mtnMomo,
      label: 'MTN Mobile Money',
      emoji: '🟡',
      color: Color(0xFFFFCC00),
    ),
    _PaymentOption(
      method: PaymentMethod.moovMoney,
      label: 'Moov Money',
      emoji: '🔵',
      color: Color(0xFF0066CC),
    ),
    _PaymentOption(
      method: PaymentMethod.wave,
      label: 'Wave',
      emoji: '🌊',
      color: Color(0xFF1DC4FF),
    ),
  ];

  static const _otherMethods = [
    _PaymentOption(
      method: PaymentMethod.card,
      label: 'Carte bancaire',
      emoji: '💳',
      color: Color(0xFF2E7D32),
    ),
    _PaymentOption(
      method: PaymentMethod.wallet,
      label: 'Wallet Flash Deals',
      emoji: '👛',
      color: Color(0xFF9C27B0),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Moyen de paiement'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // === INFO ===
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Paiement 100% sécurisé et en ligne',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // === MOBILE MONEY ===
                  _sectionTitle('📱 Mobile Money'),
                  const SizedBox(height: 8),
                  ..._mobileMoney.map((opt) => _buildOption(opt)),

                  const SizedBox(height: 20),

                  // === AUTRES ===
                  _sectionTitle('💳 Autres méthodes'),
                  const SizedBox(height: 8),
                  ..._otherMethods.map((opt) => _buildOption(opt)),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // === BOUTON CONTINUER (fixe en bas) ===
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      // 💰 PAIEMENT PAR DEALS CASH (WALLET)
                      if (_selected == PaymentMethod.wallet) {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Utilisateur non connecté')),
                          );
                          return;
                        }

                        try {
                          final response = await http.post(
                            Uri.parse('https://flash-deals-server.onrender.com/payOrder'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              'userId': user.uid,
                              'amount': widget.total,
                              'orderId': 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
                            }),
                          );

                          if (response.statusCode == 200) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Paiement validé avec Deals Cash !'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              context.go('/success');
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur : ${response.body}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur réseau : $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                        return;
                      }

                      // 💳 PAIEMENT PAR PAIEMENTPRO (logique existante)
                      String channel = 'CARD';
                      String label = 'Carte bancaire';
                      switch (_selected) {
                        case PaymentMethod.orangeMoney:
                          channel = 'ORANGE_MONEY';
                          label = 'Orange Money';
                          break;
                        case PaymentMethod.mtnMomo:
                          channel = 'MTN_MONEY';
                          label = 'MTN Mobile Money';
                          break;
                        case PaymentMethod.moovMoney:
                          channel = 'MOOV_MONEY';
                          label = 'Moov Money';
                          break;
                        case PaymentMethod.wave:
                          channel = 'WAVE';
                          label = 'Wave';
                          break;
                        case PaymentMethod.card:
                          channel = 'CARD';
                          label = 'Carte bancaire';
                          break;
                        default:
                          channel = 'CARD';
                          label = 'Paiement';
                      }
                      context.push('/payment/pro', extra: {
                        'channel': channel,
                        'channelLabel': label,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continuer',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildOption(_PaymentOption opt) {
    final isSelected = _selected == opt.method;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _selected = opt.method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? opt.color.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? opt.color : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: opt.color.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // EMOJI dans un cercle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: opt.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    opt.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // LABEL
              Expanded(
                child: Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? opt.color : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // RADIO
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? opt.color : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: opt.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentOption {
  final PaymentMethod method;
  final String label;
  final String emoji;
  final Color color;

  const _PaymentOption({
    required this.method,
    required this.label,
    required this.emoji,
    required this.color,
  });
}
