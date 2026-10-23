import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/empty_states/empty_state.dart';
import '../../widgets/skeletons/shimmer_box.dart';
import '../../widgets/snackbars/app_snackbar.dart';

class AdminDeliveriesPage extends StatefulWidget {
  const AdminDeliveriesPage({super.key});

  @override
  State<AdminDeliveriesPage> createState() => _AdminDeliveriesPageState();
}

class _AdminDeliveriesPageState extends State<AdminDeliveriesPage> {
  final _firestore = FirestoreService();
  String _filter = 'all';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historique des livraisons'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          _buildSearchBar(),
          // Filtres par statut
          _buildFilters(),
          // Liste
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestore.streamDeliveries(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: List.generate(
                      5,
                      (_) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: ShimmerBox(height: 140),
                      ),
                    ),
                  );
                }

                var orders = snapshot.data ?? [];

                // Filtrer par statut
                if (_filter != 'all') {
                  orders = orders
                      .where((o) => (o['status'] ?? 'pending') == _filter)
                      .toList();
                }

                // Filtrer par recherche
                if (_search.isNotEmpty) {
                  final q = _search.toLowerCase();
                  orders = orders.where((o) {
                    final id = (o['id'] ?? '').toString().toLowerCase();
                    final userName =
                        (o['userName'] ?? '').toString().toLowerCase();
                    final address = (o['address'] as Map?)?['fullAddress']
                            ?.toString()
                            .toLowerCase() ??
                        '';
                    return id.contains(q) ||
                        userName.contains(q) ||
                        address.contains(q);
                  }).toList();
                }

                if (orders.isEmpty) {
                  return const EmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: 'Aucune livraison',
                    subtitle:
                        'Aucune livraison dans cette catégorie pour le moment.',
                  );
                }

                // Stats rapides
                return Column(
                  children: [
                    _buildQuickStats(orders),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: orders.length,
                        itemBuilder: (context, i) =>
                            _deliveryCard(orders[i]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── SEARCH BAR ─────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          hintText: 'Rechercher (ID, client, adresse...)',
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ───────────────────────── FILTRES ─────────────────────────
  Widget _buildFilters() {
    const filters = {
      'all': 'Toutes',
      'pending': 'En attente',
      'confirmed': 'Confirmées',
      'preparing': 'En préparation',
      'onTheWay': 'En route',
      'delivered': 'Livrées',
      'cancelled': 'Annulées',
    };

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: filters.entries.map((e) {
          final selected = e.key == _filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.value),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => setState(() => _filter = e.key),
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary,
              side: BorderSide(
                color: selected
                    ? AppColors.primary
                    : Colors.grey.shade300,
              ),
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ───────────────────────── STATS RAPIDES ─────────────────────────
  Widget _buildQuickStats(List<Map<String, dynamic>> orders) {
    int delivered = 0;
    int inProgress = 0;
    int cancelled = 0;

    for (final o in orders) {
      final status = o['status'] as String? ?? 'pending';

      if (status == 'delivered') {
        delivered++;
      } else if (status == 'cancelled') {
        cancelled++;
      } else {
        inProgress++;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
              child: _statItem('${orders.length}', 'Total',
                  Icons.list_alt, AppColors.primary)),
          Container(width: 1, height: 30, color: Colors.grey.shade200),
          Expanded(
              child: _statItem('$inProgress', 'En cours',
                  Icons.delivery_dining, Colors.blue)),
          Container(width: 1, height: 30, color: Colors.grey.shade200),
          Expanded(
              child: _statItem('$delivered', 'Livrées',
                  Icons.check_circle, AppColors.success)),
          Container(width: 1, height: 30, color: Colors.grey.shade200),
          Expanded(
              child: _statItem('$cancelled', 'Annulées',
                  Icons.cancel, Colors.red)),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  // ───────────────────────── CARTE LIVRAISON ─────────────────────────
  Widget _deliveryCard(Map<String, dynamic> o) {
    final id = o['id'] as String;
    final shortId = id.substring(0, 8);
    final status = o['status'] as String? ?? 'pending';
    final total = (o['total'] as num?)?.toDouble() ?? 0;
    final userName = o['userName'] as String? ?? 'Client';
    final address = o['address'] as Map<String, dynamic>?;
    final delivery = o['delivery'] as Map<String, dynamic>?;
    final createdAt = (o['createdAt'] as Timestamp?)?.toDate();
    final deliveredAt = (o['deliveredAt'] as Timestamp?)?.toDate();

    final (color, label, icon) = _statusInfo(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── HEADER : ID + STATUS ───
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#$shortId',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (createdAt != null)
                      Text(
                        _formatDateTime(createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 10),

          // ─── CLIENT ───
          _infoRow(Icons.person_outline, userName, bold: true),
          const SizedBox(height: 6),

          // ─── ADRESSE ───
          if (address != null) ...[
            _infoRow(
              Icons.location_on_outlined,
              address['fullAddress'] as String? ?? 'Adresse inconnue',
            ),
            const SizedBox(height: 6),
            if (address['zone'] != null)
              _infoRow(
                Icons.map_outlined,
                'Zone : ${address['zone']}',
              ),
            const SizedBox(height: 6),
          ],

          // ─── CRÉNEAU ───
          if (delivery != null && delivery['timeSlot'] != null)
            _infoRow(
              Icons.access_time,
              'Créneau : ${delivery['timeSlot']}',
            ),
          const SizedBox(height: 6),

          // ─── DATES ───
          if (deliveredAt != null)
            _infoRow(
              Icons.check_circle_outline,
              'Livré le ${_formatDateTime(deliveredAt)}',
              color: AppColors.success,
            ),

          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 10),

          // ─── TOTAUX ───
          Row(
            children: [
              // Total
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      Formatters.price(total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Frais livraison
              if (delivery != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Frais livraison',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey)),
                      Text(
                        Formatters.price(
                            (delivery['fee'] as num?)?.toDouble() ?? 0),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // ─── ACTION ───
          if (status == 'onTheWay')
            SizedBox(
              width: double.infinity,
              height: 40,
              child: FilledButton.icon(
                onPressed: () => _markDelivered(id, shortId),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Marquer comme livré',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text,
      {bool bold = false, Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime d) {
    return '${d.day}/${d.month}/${d.year} • '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
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
        return (Colors.blue, 'En route', Icons.delivery_dining);
      case 'delivered':
        return (AppColors.success, 'Livrée', Icons.check_circle);
      case 'cancelled':
        return (AppColors.error, 'Annulée', Icons.cancel);
      default:
        return (Colors.grey, s, Icons.circle);
    }
  }

  void _markDelivered(String orderId, String shortId) async {
    try {
      await _firestore.markDelivered(orderId);
      if (!mounted) return;
      AppSnackbar.success(context, 'Commande #$shortId livrée');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Erreur : $e');
    }
  }
}
