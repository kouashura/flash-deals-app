import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/admin_push_service.dart';
import '../../../core/services/order_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/order.dart';
import 'widgets/admin_section.dart';
import '../../widgets/snackbars/app_snackbar.dart';

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: adminInk,
        elevation: 0,
        title: const Text(
          'Commandes',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: adminBorder),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: OrderService().streamAllOrders(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return const Center(child: Text('Aucune commande'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: orders.length,
            itemBuilder: (context, i) => _orderCard(context, orders[i]),
          );
        },
      ),
    );
  }

  Widget _orderCard(BuildContext context, Map<String, dynamic> order) {
    final id = order['id'] as String;
    final shortId = id.substring(0, 8);
    final status = order['status'] as String? ?? 'pending';
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final itemCount = (order['items'] as List?)?.length ?? 0;
    final address = order['address'] as Map<String, dynamic>?;
    final userName = order['userName'] as String? ?? 'Client';
    final createdAt = (order['createdAt'] as Timestamp?)?.toDate();
    final isGuest = order['isGuest'] as bool? ?? false;

    final (color, label) = _statusInfo(status);
    final next = _nextStatus(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: adminBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === HEADER : ID + STATUT ===
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#$shortId',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: adminInk,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 14),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            // Copier l'ID complet
                            AppSnackbar.info(context, 'ID : $id');
                          },
                        ),
                      ],
                    ),
                    if (createdAt != null)
                      Text(
                        _formatDateTime(createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: adminMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // === RÉSUMÉ ===
          Text(
            '$itemCount articles • ${Formatters.price(total)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: adminInk,
            ),
          ),

          const SizedBox(height: 12),

          // === CLIENT ===
          _infoRow(
            Icons.person_outline,
            isGuest ? 'Client invité' : userName,
            bold: true,
          ),
          const SizedBox(height: 6),
          _infoRow(
            Icons.location_on_outlined,
            address?['fullAddress'] as String? ?? 'Adresse inconnue',
          ),
          if (address != null) ...[
            const SizedBox(height: 4),
            _infoRow(
              Icons.map_outlined,
              'Zone : ${address['zone'] ?? "Non spécifiée"}',
            ),
          ],

          const SizedBox(height: 14),

          // === ACTION ===
          if (next != null)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton.icon(
                onPressed: () => _advance(context, order, next),
                icon: Icon(_iconFor(next), size: 18),
                label: Text(
                  _labelFor(next),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _colorFor(next),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_iconFor(status), color: color, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    status == 'cancelled'
                        ? 'Commande annulée'
                        : 'Commande livrée',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {bool bold = false}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: adminMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: adminInk,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime d) {
    return '${d.day}/${d.month}/${d.year} à '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _advance(
      BuildContext context,
      Map<String, dynamic> order,
      String nextStatus) async {
    final orderId = order['id'] as String;
    final userId = order['userId'] as String?;

    // 1. Mettre à jour le statut
    await OrderService().updateOrderStatus(
      orderId: orderId,
      status: OrderStatus.values.firstWhere((e) => e.name == nextStatus),
    );

    // 2. Envoyer la notification push
    if (userId != null) {
      await AdminPushService.sendOrderUpdate(
        orderId: orderId,
        userId: userId,
        status: nextStatus,
      );
    }

    if (!context.mounted) return;
    AppSnackbar.info(
        context, 'Statut mis à jour : ${_labelFor(nextStatus)}');
  }

  String? _nextStatus(String s) {
    switch (s) {
      case 'pending':
        return 'confirmed';
      case 'confirmed':
        return 'preparing';
      case 'preparing':
        return 'onTheWay';
      case 'onTheWay':
        return 'delivered';
      default:
        return null;
    }
  }

  (Color, String) _statusInfo(String status) {
    switch (status) {
      case 'pending':
        return (Colors.grey, 'En attente');
      case 'confirmed':
        return (AppColors.primary, 'Confirmée');
      case 'preparing':
        return (Colors.orange, 'En préparation');
      case 'onTheWay':
        return (Colors.blue, 'En route');
      case 'delivered':
        return (AppColors.success, 'Livrée');
      case 'cancelled':
        return (AppColors.error, 'Annulée');
      default:
        return (Colors.grey, status);
    }
  }

  String _labelFor(String s) {
    switch (s) {
      case 'confirmed':
        return 'Confirmer la commande';
      case 'preparing':
        return 'Marquer en préparation';
      case 'onTheWay':
        return 'Marquer en route';
      case 'delivered':
        return 'Marquer livrée';
      default:
        return s;
    }
  }

  IconData _iconFor(String s) {
    switch (s) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.inventory_2_outlined;
      case 'onTheWay':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.home_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.circle;
    }
  }

  Color _colorFor(String s) {
    switch (s) {
      case 'confirmed':
        return AppColors.primary;
      case 'preparing':
        return Colors.orange;
      case 'onTheWay':
        return Colors.blue;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }
}
