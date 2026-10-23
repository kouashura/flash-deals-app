#!/bin/bash
echo "Refonte design admin (version pro)..."

mkdir -p lib/presentation/pages/admin/widgets

# ============================================================
# WIDGET: ADMIN SECTION
# ============================================================
cat > lib/presentation/pages/admin/widgets/admin_section.dart << 'DART'
import 'package:flutter/material.dart';

const adminBorder = Color(0xFFE9E9EE);
const adminInk = Color(0xFF1B1B1F);
const adminMuted = Color(0xFF6E6E78);

class AdminSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const AdminSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(const Divider(height: 1, indent: 66, color: adminBorder));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: adminInk,
            ),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: adminBorder),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }
}
DART

# ============================================================
# WIDGET: ADMIN STAT CARD
# ============================================================
cat > lib/presentation/pages/admin/widgets/admin_stat_card.dart << 'DART'
import 'package:flutter/material.dart';
import 'admin_section.dart';

class AdminStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const AdminStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: adminBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        color: adminInk,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: adminMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
DART

# ============================================================
# WIDGET: ADMIN MENU TILE
# ============================================================
cat > lib/presentation/pages/admin/widgets/admin_menu_tile.dart << 'DART'
import 'package:flutter/material.dart';
import 'admin_section.dart';

class AdminMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const AdminMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: adminInk,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: adminMuted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: adminMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
DART

# ============================================================
# PAGE: ADMIN DASHBOARD
# ============================================================
cat > lib/presentation/pages/admin/admin_dashboard_page.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import 'widgets/admin_section.dart';
import 'widgets/admin_stat_card.dart';
import 'widgets/admin_menu_tile.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 4 : 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: adminInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Tableau de bord',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Quitter l\'admin',
            onPressed: () => context.go('/home'),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: adminBorder),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Revenus du jour',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: const Text(
                                '158 000 FCFA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '24 commandes aujourd\'hui',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.trending_up,
                            color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'Aperçu',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: adminInk,
                    ),
                  ),
                ),
                GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.45,
                  children: [
                    AdminStatCard(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Commandes',
                      value: '24',
                      color: AppColors.primary,
                      onTap: () => context.push('/admin/orders'),
                    ),
                    AdminStatCard(
                      icon: Icons.delivery_dining_outlined,
                      label: 'En livraison',
                      value: '5',
                      color: Colors.blue,
                      onTap: () => context.push('/admin/orders'),
                    ),
                    AdminStatCard(
                      icon: Icons.inventory_2_outlined,
                      label: 'Produits',
                      value: '6',
                      color: Colors.teal,
                      onTap: () => context.push('/admin/products'),
                    ),
                    AdminStatCard(
                      icon: Icons.people_outline,
                      label: 'Clients',
                      value: '132',
                      color: Colors.purple,
                      onTap: () => context.push('/admin/users'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AdminSection(
                  title: 'Gestion',
                  children: [
                    AdminMenuTile(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Commandes',
                      subtitle: 'Suivre et mettre à jour les commandes',
                      color: AppColors.primary,
                      onTap: () => context.push('/admin/orders'),
                    ),
                    AdminMenuTile(
                      icon: Icons.inventory_2_outlined,
                      title: 'Produits',
                      subtitle: 'Ajouter, modifier, supprimer',
                      color: Colors.teal,
                      onTap: () => context.push('/admin/products'),
                    ),
                    AdminMenuTile(
                      icon: Icons.category_outlined,
                      title: 'Catégories',
                      subtitle: 'Organiser le catalogue',
                      color: Colors.orange,
                      onTap: () => context.push('/admin/categories'),
                    ),
                    AdminMenuTile(
                      icon: Icons.store_outlined,
                      title: 'Magasins',
                      subtitle: 'Grandes surfaces partenaires',
                      color: Colors.indigo,
                      onTap: () => context.push('/admin/stores'),
                    ),
                    AdminMenuTile(
                      icon: Icons.people_outline,
                      title: 'Utilisateurs',
                      subtitle: 'Clients inscrits',
                      color: Colors.purple,
                      onTap: () => context.push('/admin/users'),
                    ),
                    AdminMenuTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Envoyer une notification push',
                      color: Colors.red,
                      onTap: () => context.push('/admin/notifications'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
DART

# ============================================================
# PAGE: ADMIN ORDERS
# ============================================================
cat > lib/presentation/pages/admin/admin_orders_page.dart << 'DART'
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/delivery_status_service.dart';
import '../../../domain/entities/delivery.dart';
import 'widgets/admin_section.dart';

enum _Filter { all, active, done }

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final _service = DeliveryStatusService();
  StreamSubscription? _sub;
  _Filter _filter = _Filter.all;

  final List<_AdminOrder> _orders = [
    _AdminOrder(
      id: 'FD-1001',
      customerName: 'Kouassi Yao',
      phone: '+225 07 00 00 00 00',
      address: 'Cocody, pharmacie Mai',
      total: 4500,
      itemCount: 3,
      zone: 'Cocody',
    ),
    _AdminOrder(
      id: 'FD-1002',
      customerName: 'Aya Koffi',
      phone: '+225 05 11 22 33 44',
      address: 'Plateau, Rue du Commerce',
      total: 2800,
      itemCount: 2,
      zone: 'Plateau',
    ),
    _AdminOrder(
      id: 'FD-1003',
      customerName: 'Moussa Traoré',
      phone: '+225 01 99 88 77 66',
      address: 'Yopougon, Siporex',
      total: 6200,
      itemCount: 5,
      zone: 'Yopougon',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _sub = _service.updates.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  bool _isDone(DeliveryStatus s) =>
      s == DeliveryStatus.delivered || s == DeliveryStatus.cancelled;

  List<_AdminOrder> get _visible {
    return _orders.where((o) {
      final done = _isDone(_service.getStatus(o.id));
      switch (_filter) {
        case _Filter.all:
          return true;
        case _Filter.active:
          return !done;
        case _Filter.done:
          return done;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final orders = _visible;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: adminInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Commandes',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => setState(() {}),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: adminBorder),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: orders.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucune commande dans cette catégorie',
                            style: TextStyle(color: adminMuted),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: orders.length,
                          itemBuilder: (context, i) =>
                              _buildOrderCard(orders[i]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    const labels = {
      _Filter.all: 'Toutes',
      _Filter.active: 'En cours',
      _Filter.done: 'Terminées',
    };

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: _Filter.values.map((f) {
          final selected = f == _filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(labels[f]!),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => setState(() => _filter = f),
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary,
              side: BorderSide(
                color: selected ? AppColors.primary : adminBorder,
              ),
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : adminInk,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderCard(_AdminOrder order) {
    final status = _service.getStatus(order.id);
    final next = _service.nextStep(status);
    final color = _colorFor(status);

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
          Row(
            children: [
              Expanded(
                child: Text(
                  order.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: adminInk,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _statusChip(status, color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${order.itemCount} articles  •  ${_fcfa(order.total)} FCFA',
            style: const TextStyle(fontSize: 12, color: adminMuted),
          ),
          const SizedBox(height: 14),
          _progressBar(status, color),
          const SizedBox(height: 14),
          _infoRow(Icons.person_outline, order.customerName, bold: true),
          const SizedBox(height: 8),
          _infoRow(Icons.phone_outlined, order.phone),
          const SizedBox(height: 8),
          _infoRow(Icons.location_on_outlined, order.address),
          const SizedBox(height: 8),
          _infoRow(Icons.map_outlined, 'Zone ${order.zone}'),
          const SizedBox(height: 16),
          if (next != null)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: () => _advanceStatus(order, next),
                icon: Icon(_iconFor(next), size: 18),
                label: Text(
                  DeliveryStatusService.labelFor(next),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                    status == DeliveryStatus.cancelled
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
          if (!_isDone(status))
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => _confirmCancel(order),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                child: const Text(
                  'Annuler la commande',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusChip(DeliveryStatus status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            DeliveryStatusService.labelFor(status),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar(DeliveryStatus status, Color color) {
    int filled;
    switch (status) {
      case DeliveryStatus.pending:
        filled = 0;
        break;
      case DeliveryStatus.confirmed:
        filled = 1;
        break;
      case DeliveryStatus.preparing:
        filled = 2;
        break;
      case DeliveryStatus.onTheWay:
        filled = 3;
        break;
      case DeliveryStatus.delivered:
        filled = 4;
        break;
      case DeliveryStatus.cancelled:
        filled = 0;
        break;
    }

    return Row(
      children: List.generate(4, (i) {
        final on = i < filled;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
            decoration: BoxDecoration(
              color: on ? color : adminBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _infoRow(IconData icon, String text, {bool bold = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: adminMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: adminInk,
            ),
          ),
        ),
      ],
    );
  }

  void _advanceStatus(_AdminOrder order, DeliveryStatus next) {
    _service.updateStatus(
      orderId: order.id,
      newStatus: next,
      note: 'Mis à jour par admin',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: adminInk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          '${order.id} : ${DeliveryStatusService.labelFor(next)}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmCancel(_AdminOrder order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Annuler la commande ?'),
        content: Text(
          'La commande ${order.id} de ${order.customerName} sera annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Retour'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Annuler la commande'),
          ),
        ],
      ),
    );

    if (ok == true) {
      _service.updateStatus(
        orderId: order.id,
        newStatus: DeliveryStatus.cancelled,
        note: 'Annulée par admin',
      );
    }
  }

  String _fcfa(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  IconData _iconFor(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.pending:
        return Icons.hourglass_empty;
      case DeliveryStatus.confirmed:
        return Icons.check_circle_outline;
      case DeliveryStatus.preparing:
        return Icons.inventory_2_outlined;
      case DeliveryStatus.onTheWay:
        return Icons.delivery_dining;
      case DeliveryStatus.delivered:
        return Icons.home_outlined;
      case DeliveryStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Color _colorFor(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.pending:
        return Colors.blueGrey;
      case DeliveryStatus.confirmed:
        return AppColors.primary;
      case DeliveryStatus.preparing:
        return Colors.orange;
      case DeliveryStatus.onTheWay:
        return Colors.blue;
      case DeliveryStatus.delivered:
        return AppColors.success;
      case DeliveryStatus.cancelled:
        return AppColors.error;
    }
  }
}

class _AdminOrder {
  final String id;
  final String customerName;
  final String phone;
  final String address;
  final int total;
  final int itemCount;
  final String zone;

  _AdminOrder({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.total,
    required this.itemCount,
    required this.zone,
  });
}
DART

echo "Design admin refait !"
