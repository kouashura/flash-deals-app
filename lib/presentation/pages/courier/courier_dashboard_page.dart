import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/courier/courier_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/courier.dart';
import '../../widgets/snackbars/app_snackbar.dart';

class CourierDashboardPage extends StatefulWidget {
  const CourierDashboardPage({super.key});

  @override
  State<CourierDashboardPage> createState() => _CourierDashboardPageState();
}

class _CourierDashboardPageState extends State<CourierDashboardPage> {
  bool _togglingStatus = false;

  Future<void> _toggleAvailability(bool value) async {
    setState(() => _togglingStatus = true);
    try {
      await CourierService.setAvailability(value);
      if (mounted) {
        AppSnackbar.success(
          context,
          value ? 'Vous êtes disponible' : 'Vous êtes indisponible',
        );
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _togglingStatus = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.logout, color: Colors.red, size: 28),
        ),
        title: const Text('Se déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await CourierService.logout();
      if (mounted) context.go('/courier/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Courier?>(
      stream: CourierService.streamCurrentCourier(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final courier = snapshot.data;
        if (courier == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Session expirée'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/courier/login'),
                    child: const Text('Se reconnecter'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Tableau de bord'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logout,
                tooltip: 'Déconnexion',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ═══ STATUT DE VÉRIFICATION ═══
              if (courier.status == CourierStatus.pending)
                _statusBanner(
                  color: Colors.orange,
                  icon: Icons.hourglass_empty,
                  title: 'En attente de validation',
                  subtitle:
                      'Votre compte sera vérifié sous 24h par un administrateur.',
                )
              else if (courier.status == CourierStatus.approved)
                _statusBanner(
                  color: AppColors.success,
                  icon: Icons.verified,
                  title: 'Compte validé',
                  subtitle: 'Vous pouvez commencer à livrer !',
                )
              else if (courier.status == CourierStatus.rejected)
                _statusBanner(
                  color: AppColors.error,
                  icon: Icons.cancel,
                  title: 'Compte refusé',
                  subtitle: 'Contactez le support pour plus d\'infos.',
                ),

              const SizedBox(height: 16),

              // ═══ PROFIL ═══
              _profileCard(courier),

              const SizedBox(height: 16),

              // ═══ DISPONIBILITÉ ═══
              if (courier.status == CourierStatus.approved)
                _availabilityCard(courier),

              const SizedBox(height: 16),

              // ═══ STATISTIQUES ═══
              _statsCard(courier),

              const SizedBox(height: 16),

              // ═══ MENU ═══
              _menuCard(courier),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════
  // WIDGETS
  // ═══════════════════════════════════════
  Widget _statusBanner({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileCard(Courier courier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary,
            backgroundImage: courier.photoUrl != null &&
                    courier.photoUrl!.isNotEmpty
                ? NetworkImage(courier.photoUrl!)
                : null,
            child: courier.photoUrl == null || courier.photoUrl!.isEmpty
                ? Text(
                    courier.fullName.isNotEmpty
                        ? courier.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  courier.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  courier.phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.two_wheeler,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${courier.vehicleType.label} • ${courier.zone}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _availabilityCard(Courier courier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (courier.isAvailable ? AppColors.success : Colors.grey)
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              courier.isAvailable ? Icons.check_circle : Icons.pause_circle,
              color: courier.isAvailable ? AppColors.success : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  courier.isAvailable ? 'Disponible' : 'Indisponible',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  courier.isAvailable
                      ? 'Vous recevez des commandes'
                      : 'Activez pour recevoir des commandes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: courier.isAvailable,
            onChanged: _togglingStatus ? null : _toggleAvailability,
            activeColor: Colors.white,
            activeTrackColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _statsCard(Courier courier) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFFFF9800)],
        ),
        borderRadius: BorderRadius.circular(16),
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
            child: _statItem(
              Icons.local_shipping,
              '${courier.totalDeliveries}',
              'Livraisons',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.25),
          ),
          Expanded(
            child: _statItem(
              Icons.attach_money,
              Formatters.price(courier.totalEarnings),
              'Gains',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.25),
          ),
          Expanded(
            child: _statItem(
              Icons.star,
              courier.rating.toStringAsFixed(1),
              'Note',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _menuCard(Courier courier) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _menuTile(
            Icons.list_alt,
            'Mes livraisons',
            'Voir l\'historique',
            () => context.push('/courier/orders'),
          ),
          Divider(height: 1, indent: 60, color: Colors.grey.shade200),
          _menuTile(
            Icons.map,
            'Ma zone',
            'Modifier ma zone de livraison',
            () {},
          ),
          Divider(height: 1, indent: 60, color: Colors.grey.shade200),
          _menuTile(
            Icons.account_balance_wallet,
            'Mes gains',
            'Voir les détails',
            () {},
          ),
          Divider(height: 1, indent: 60, color: Colors.grey.shade200),
          _menuTile(
            Icons.help_outline,
            'Aide',
            'Contacter le support',
            () {},
          ),
        ],
      ),
    );
  }

  Widget _menuTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
