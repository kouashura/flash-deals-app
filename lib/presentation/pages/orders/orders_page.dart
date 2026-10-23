import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/order_service.dart';
import '../../../core/utils/formatters.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mes commandes')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: OrderService().streamUserOrders(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Aucune commande'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, i) => _orderCard(context, orders[i]),
          );
        },
      ),
    );
  }

  Widget _orderCard(BuildContext context, Map<String, dynamic> order) {
    final id = order['id'] as String;
    final status = order['status'] as String? ?? 'pending';
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final itemCount = (order['items'] as List?)?.length ?? 0;
    final createdAt = (order['createdAt'] as Timestamp?)?.toDate();

    final (color, label) = _statusInfo(status);

    return GestureDetector(
      onTap: () => context.push('/orders/tracking?id=$id'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${id.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (createdAt != null)
                    Text(
                      Formatters.dateTime(createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '$itemCount articles • ${Formatters.price(total)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
}
