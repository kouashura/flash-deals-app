import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/maps/delivery_map.dart';
import '../../../core/services/pdf_service.dart';
import '../../widgets/snackbars/app_snackbar.dart';

class OrderTrackingPage extends StatelessWidget {
  final String orderId;
  const OrderTrackingPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Suivi #${orderId.substring(0, 8)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Erreur : ${snapshot.error}',
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? 'pending';
          final total = (data['total'] as num?)?.toDouble() ?? 0;
          final address = data['address'] as Map<String, dynamic>?;
          final delivery = data['delivery'] as Map<String, dynamic>?;
          final items = data['items'] as List<dynamic>? ?? [];

          final clientPosition = _getClientPosition(address);
          const storePosition = LatLng(5.3561, -3.9876);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _statusCard(status),
              const SizedBox(height: 16),

              // ═══ CARTE ═══
              if (clientPosition != null) ...[
                const Text(
                  '🗺️ Suivi en temps réel',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                DeliveryMap(
                  storePosition: storePosition,
                  clientPosition: clientPosition,
                  storeName: 'Carrefour Cocody',
                  status: status,
                  height: 280,
                ),
                const SizedBox(height: 20),
              ],

              // ═══ PROGRESSION ═══
              const Text(
                '📊 Progression',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              _progressBar(status),

              const SizedBox(height: 20),

              // ═══ TIMELINE ═══
              const Text(
                '📋 Historique',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              _timeline(status),

              const SizedBox(height: 20),

              // ═══ ADRESSE ═══
              const Text(
                '📍 Adresse de livraison',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              _infoCard(
                Icons.location_on,
                'Adresse',
                address?['fullAddress'] as String? ?? 'Adresse inconnue',
              ),
              const SizedBox(height: 10),
              _infoCard(
                Icons.access_time,
                'Créneau',
                delivery?['timeSlot'] as String? ?? 'Non défini',
              ),

              const SizedBox(height: 20),

              // ═══ LIVREUR ═══
              if (status == 'onTheWay' || status == 'delivered') ...[
                const Text(
                  '🚚 Votre livreur',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                _courierCard(),
                const SizedBox(height: 20),
              ],

              // ═══ BOUTON DONNER MON AVIS ═══
              if (status == 'delivered' &&
                  (data['reviewed'] != true)) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.star,
                          color: Colors.amber, size: 32),
                      const SizedBox(height: 8),
                      const Text(
                        'Donnez votre avis !',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Aidez les autres clients en partageant votre expérience',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: FilledButton.icon(
                          onPressed: () {
                            // Prendre le premier produit
                            if (items.isEmpty) return;
                            final firstItem = items.first;
                            context.push(
                              '/review/write',
                              extra: {
                                'productId': firstItem['productId'] ?? '',
                                'orderId': orderId,
                                'productName':
                                    firstItem['name'] ?? 'Produit',
                                'productImage':
                                    firstItem['imageUrl'] ?? '',
                              },
                            );
                          },
                          icon: const Icon(Icons.star,
                              color: Colors.white, size: 18),
                          label: const Text(
                            'Donner mon avis',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ═══ RÉCAPITULATIF ═══
              const Text(
                '🧾 Récapitulatif',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              _summaryCard(items, total),

              const SizedBox(height: 20),

              // ═══ BOUTON FACTURE PDF ═══
              SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _downloadInvoice(
                    context,
                    orderId: orderId,
                    createdAt:
                        (data['createdAt'] as Timestamp?)?.toDate() ??
                            DateTime.now(),
                    customerName:
                        data['userName'] as String? ?? 'Client',
                    customerPhone:
                        data['userPhone'] as String? ??
                            address?['phone'] as String? ??
                            '+225 XX XX XX XX',
                    customerAddress:
                        address?['fullAddress'] as String? ??
                            'Adresse inconnue',
                    items: items
                        .map((e) => {
                              'name': e['name'] ?? 'Article',
                              'quantity': e['quantity'] ?? 0,
                              'price': e['price'] ?? 0,
                              'total': e['total'] ?? 0,
                            })
                        .toList(),
                    subtotal:
                        (data['subtotal'] as num?)?.toDouble() ?? total,
                    deliveryFee:
                        (delivery?['fee'] as num?)?.toInt() ?? 0,
                    total: total,
                    deliveryZone: address?['zone'] as String?,
                    timeSlot: delivery?['timeSlot'] as String?,
                  ),
                  icon: const Icon(Icons.picture_as_pdf,
                      color: Colors.white),
                  label: const Text(
                    'Télécharger la facture PDF',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
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

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════
  // TÉLÉCHARGER LA FACTURE PDF
  // ═══════════════════════════════════════
  Future<void> _downloadInvoice(
    BuildContext context, {
    required String orderId,
    required DateTime createdAt,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required int deliveryFee,
    required double total,
    String? deliveryZone,
    String? timeSlot,
  }) async {
    try {
      await PdfService.generateInvoice(
        orderId: orderId,
        createdAt: createdAt,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        items: items,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
        deliveryZone: deliveryZone,
        timeSlot: timeSlot,
      );
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Erreur PDF : $e');
      }
    }
  }

  // ═══════════════════════════════════════
  // STATUT
  // ═══════════════════════════════════════
  Widget _statusCard(String status) {
    final (color, label, icon) = _statusInfo(status);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Statut actuel',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // PROGRESSION
  // ═══════════════════════════════════════
  Widget _progressBar(String currentStatus) {
    final steps = ['confirmed', 'preparing', 'onTheWay', 'delivered'];
    final idx = steps.indexOf(currentStatus).clamp(0, 4);
    final currentIndex = idx;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final lineIndex = i ~/ 2;
            final isActive = lineIndex < currentIndex;
            return Expanded(
              child: Container(
                height: 3,
                color: isActive ? AppColors.success : Colors.grey.shade300,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isDone = stepIndex <= currentIndex;
          return Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isDone ? AppColors.success : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconFor(steps[stepIndex]),
              color: Colors.white,
              size: 15,
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════
  // TIMELINE
  // ═══════════════════════════════════════
  Widget _timeline(String currentStatus) {
    final steps = ['confirmed', 'preparing', 'onTheWay', 'delivered'];
    final idx = steps.indexOf(currentStatus).clamp(0, 4);
    final currentIndex = idx;

    final labels = {
      'confirmed': 'Commande confirmée',
      'preparing': 'En préparation au magasin',
      'onTheWay': 'Livreur en route',
      'delivered': 'Colis livré',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(steps.length, (i) {
          final step = steps[i];
          final done = i <= currentIndex;
          final isLast = i == steps.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: done
                            ? AppColors.success
                            : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _iconFor(step),
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: done
                              ? AppColors.success
                              : Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Text(
                      labels[step] ?? step,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: done ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════
  // INFO CARD
  // ═══════════════════════════════════════
  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // LIVREUR
  // ═══════════════════════════════════════
  Widget _courierCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.person, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Yao (Livreur)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '+225 07 XX XX XX XX',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: AppColors.success, size: 20),
            onPressed: () {},
            tooltip: 'Appeler',
          ),
          IconButton(
            icon: const Icon(Icons.message,
                color: AppColors.primary, size: 20),
            onPressed: () {},
            tooltip: 'Message',
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // RÉCAPITULATIF
  // ═══════════════════════════════════════
  Widget _summaryCard(List<dynamic> items, double total) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Aucun article',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            )
          else
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item['quantity']}× ${item['name']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.price(
                          (item['total'] as num?)?.toDouble() ?? 0),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          Divider(color: Colors.grey.shade200),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'TOTAL',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    Formatters.price(total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════
  LatLng? _getClientPosition(Map<String, dynamic>? address) {
    if (address == null) return null;
    final lat = address['latitude'] as num?;
    final lng = address['longitude'] as num?;
    if (lat == null || lng == null) return null;
    return LatLng(lat.toDouble(), lng.toDouble());
  }

  (Color, String, IconData) _statusInfo(String s) {
    switch (s) {
      case 'pending':
        return (Colors.grey, 'En attente', Icons.hourglass_empty);
      case 'confirmed':
        return (AppColors.primary, 'Confirmée', Icons.check_circle);
      case 'preparing':
        return (Colors.orange, 'En préparation', Icons.inventory_2);
      case 'onTheWay':
        return (Colors.blue, 'En cours de livraison', Icons.delivery_dining);
      case 'delivered':
        return (AppColors.success, 'Livré 🎉', Icons.home);
      case 'cancelled':
        return (AppColors.error, 'Annulée', Icons.cancel);
      default:
        return (Colors.grey, s, Icons.info);
    }
  }

  IconData _iconFor(String s) {
    switch (s) {
      case 'confirmed':
        return Icons.check_circle;
      case 'preparing':
        return Icons.inventory_2;
      case 'onTheWay':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.home;
      default:
        return Icons.circle;
    }
  }
}
