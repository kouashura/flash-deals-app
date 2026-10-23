import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/formatters.dart';
import 'widgets/admin_section.dart';
import 'widgets/admin_stat_card.dart';
import 'widgets/admin_menu_tile.dart';
import '../../widgets/skeletons/shimmer_box.dart';

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
        child: StreamBuilder<Map<String, dynamic>>(
          stream: FirestoreService().streamDashboardStats(),
          builder: (context, snapshot) {
            final stats = snapshot.data ?? {};
            final isLoading = !snapshot.hasData;

            final revenue =
                (stats['totalRevenue'] as num?)?.toDouble() ?? 0;
            final totalOrders = stats['totalOrders'] as int? ?? 0;
            final inDelivery = stats['inDelivery'] as int? ?? 0;
            final totalProducts = stats['totalProducts'] as int? ?? 0;
            final totalClients = stats['totalClients'] as int? ?? 0;
            final totalCategories = stats['totalCategories'] as int? ?? 0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ═══ CARTE REVENUS ═══
                    _buildRevenueCard(revenue, totalOrders, isLoading),

                    const SizedBox(height: 24),

                    // ═══ STATS GRID ═══
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
                    isLoading
                        ? _buildStatsSkeleton(crossAxisCount)
                        : GridView.count(
                            crossAxisCount: crossAxisCount,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.05,
                            children: [
                              AdminStatCard(
                                icon: Icons.shopping_bag_outlined,
                                label: 'Commandes',
                                value: '$totalOrders',
                                color: AppColors.primary,
                                onTap: () =>
                                    context.push('/admin/orders'),
                              ),
                              AdminStatCard(
                                icon: Icons.delivery_dining_outlined,
                                label: 'En livraison',
                                value: '$inDelivery',
                                color: Colors.blue,
                                onTap: () =>
                                    context.push('/admin/orders'),
                              ),
                              AdminStatCard(
                                icon: Icons.inventory_2_outlined,
                                label: 'Produits',
                                value: '$totalProducts',
                                color: Colors.teal,
                                onTap: () =>
                                    context.push('/admin/products'),
                              ),
                              AdminStatCard(
                                icon: Icons.people_outline,
                                label: 'Clients',
                                value: '$totalClients',
                                color: Colors.purple,
                                onTap: () =>
                                    context.push('/admin/users'),
                              ),
                              AdminStatCard(
                                icon: Icons.category_outlined,
                                label: 'Catégories',
                                value: '$totalCategories',
                                color: Colors.orange,
                                onTap: () =>
                                    context.push('/admin/categories'),
                              ),
                              AdminStatCard(
                                icon: Icons.store_outlined,
                                label: 'Magasins',
                                value: '—',
                                color: Colors.indigo,
                                onTap: () =>
                                    context.push('/admin/stores'),
                              ),
                            ],
                          ),

                    const SizedBox(height: 24),

                    // ═══ MENU GESTION ═══
                    AdminSection(
                      title: 'Gestion',
                      children: [
                        AdminMenuTile(
                          icon: Icons.shopping_bag_outlined,
                          title: 'Commandes',
                          subtitle: 'Suivre et mettre à jour',
                          color: AppColors.primary,
                          onTap: () => context.push('/admin/orders'),
                        ),
                        AdminMenuTile(
                          icon: Icons.local_shipping_outlined,
                          title: 'Historique livraisons',
                          subtitle: 'Tout voir sur les livraisons',
                          color: Colors.blue,
                          onTap: () => context.push('/admin/deliveries'),
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
                          onTap: () =>
                              context.push('/admin/notifications'),
                        ),
                        AdminMenuTile(
                          icon: Icons.flash_on,
                          title: 'Bannière Vente Flash',
                          subtitle: 'Configurer le compte à rebours',
                          color: Colors.amber,
                          onTap: () => context.push('/admin/flash-deals'),
                        ),
                        AdminMenuTile(
                          icon: Icons.settings_suggest_outlined,
                          title: 'Initialiser Firestore',
                          subtitle: 'Créer les collections (dev)',
                          color: Colors.deepOrange,
                          onTap: () => context.push('/admin/seed'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══ CARTE REVENUS ═══
  Widget _buildRevenueCard(
      double revenue, int totalOrders, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFFFF9800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.trending_up,
                          color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Revenus totaux',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  const ShimmerBox(
                    width: 160,
                    height: 34,
                    borderRadius: 8,
                  )
                else
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Formatters.price(revenue),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  isLoading
                      ? 'Chargement...'
                      : '$totalOrders commande${totalOrders > 1 ? "s" : ""} au total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.attach_money,
                color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  // ═══ SKELETON ═══
  Widget _buildStatsSkeleton(int crossAxisCount) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: List.generate(
        6,
        (_) => const ShimmerBox(borderRadius: 14),
      ),
    );
  }
}
