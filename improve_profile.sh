#!/bin/bash
echo "👤 Amélioration page profil..."

mkdir -p lib/presentation/pages/profile/widgets

# ============================================================
# PAGE: PROFILE (nouvelle version pro)
# ============================================================
cat > lib/presentation/pages/profile/profile_page.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/admin_auth_service.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _aboutTapCount = 0;
  DateTime? _lastAboutTap;

  // Notifications & thème (stockés en local pour l'instant)
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  void _handleAboutTap() {
    final now = DateTime.now();
    if (_lastAboutTap == null ||
        now.difference(_lastAboutTap!) > const Duration(milliseconds: 1500)) {
      _aboutTapCount = 0;
    }
    _lastAboutTap = now;
    _aboutTapCount++;

    if (_aboutTapCount >= 3) {
      _aboutTapCount = 0;
      _showAdminPasswordDialog();
    }
  }

  void _showAdminPasswordDialog() {
    final ctrl = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.admin_panel_settings,
                      color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Accès administrateur',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Réservé au personnel autorisé.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ctrl,
                    obscureText: obscure,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setStateDialog(() => obscure = !obscure);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (AdminAuthService.verifyPassword(ctrl.text)) {
                      Navigator.pop(dialogContext);
                      context.push('/admin');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('❌ Mot de passe incorrect'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      ctrl.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text(
                    'Valider',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon profil'),
        elevation: 0,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return _buildNotConnected(context);
          }
          return _buildConnected(context, state);
        },
      ),
    );
  }

  // ==========================================================
  // NON CONNECTÉ
  // ==========================================================
  Widget _buildNotConnected(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Bienvenue sur Flash Deals',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connectez-vous pour accéder à votre profil, '
              'suivre vos commandes et cumuler des points fidélité.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.push('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Se connecter',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => context.push('/register'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Créer un compte',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.card_giftcard,
                    color: AppColors.primary.withOpacity(0.7), size: 16),
                const SizedBox(width: 6),
                const Text(
                  '50 points offerts à l\'inscription',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CONNECTÉ
  // ==========================================================
  Widget _buildConnected(BuildContext context, AuthAuthenticated state) {
    final user = state.user;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // === EN-TÊTE PROFIL ===
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white,
                      child: Text(
                        user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 34,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                user.fullName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.phone,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              if (user.email.isNotEmpty)
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              const SizedBox(height: 16),

              // Bouton modifier
              OutlinedButton.icon(
                onPressed: () => _editProfile(context, user),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Modifier mon profil'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),

        // === STATS ===
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _statCard(
                  Icons.receipt_long,
                  '12',
                  'Commandes',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  Icons.card_giftcard,
                  '${user.loyaltyPoints}',
                  'Points',
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  Icons.savings,
                  '24K',
                  'Économies',
                  AppColors.success,
                ),
              ),
            ],
          ),
        ),

        // === MENU PRINCIPAL ===
        _menuSection('Mon compte', [
          _menuTile(
            Icons.receipt_long,
            'Mes commandes',
            'Suivre mes livraisons',
            () => context.push('/orders'),
          ),
          _menuTile(
            Icons.favorite_border,
            'Mes favoris',
            'Produits sauvegardés',
            () => context.push('/favorites'),
          ),
          _menuTile(
            Icons.location_on_outlined,
            'Mes adresses',
            'Gérer mes adresses de livraison',
            () => context.push('/profile/addresses'),
          ),
          _menuTile(
            Icons.credit_card,
            'Moyens de paiement',
            'Mobile Money, CB, Wallet',
            () => context.push('/profile/payments'),
          ),
        ]),

        // === MENU PRÉFÉRENCES ===
        _menuSection('Préférences', [
          _switchTile(
            Icons.notifications_outlined,
            'Notifications',
            'Recevoir les alertes deals',
            _notificationsEnabled,
            (v) => setState(() => _notificationsEnabled = v),
          ),
          _switchTile(
            Icons.dark_mode_outlined,
            'Mode sombre',
            'Confort visuel la nuit',
            _darkModeEnabled,
            (v) => setState(() => _darkModeEnabled = v),
          ),
          _menuTile(
            Icons.settings_outlined,
            'Paramètres',
            'Langue, devise, sécurité',
            () => context.push('/profile/settings'),
          ),
        ]),

        // === MENU SUPPORT ===
        _menuSection('Support', [
          _menuTile(
            Icons.help_outline,
            'Aide & support',
            'FAQ, contact',
            () => context.push('/profile/help'),
          ),
          _menuTile(
            Icons.gavel,
            'Conditions d\'utilisation',
            'Lire les CGU',
            () => context.push('/profile/terms'),
          ),
          _menuTile(
            Icons.privacy_tip_outlined,
            'Politique de confidentialité',
            'Vos données',
            () => context.push('/profile/privacy'),
          ),
          _menuTile(
            Icons.info_outline,
            'À propos',
            'Version 1.0.0',
            _handleAboutTap,
          ),
        ]),

        // === DÉCONNEXION ===
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Se déconnecter',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // ==========================================================
  // WIDGETS
  // ==========================================================
  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _menuSection(String title, List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8, top: 4),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  items[i],
                  if (i < items.length - 1)
                    const Divider(
                      height: 1,
                      indent: 56,
                      color: Color(0xFFEEEEEE),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(
    IconData icon,
    String title,
    String? subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  if (subtitle != null)
                    Text(
                      subtitle,
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
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _switchTile(
    IconData icon,
    String title,
    String? subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ACTIONS
  // ==========================================================
  void _editProfile(BuildContext context, user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final emailCtrl = TextEditingController(text: user.email);
    final phoneCtrl = TextEditingController(text: user.phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Poignée
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Modifier mon profil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Profil mis à jour'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Enregistrer',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Vous devrez vous reconnecter pour accéder à votre compte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(const LogoutRequested());
              context.go('/home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
DART

# ============================================================
# PAGES ANNEXES (vides mais fonctionnelles)
# ============================================================

cat > lib/presentation/pages/profile/addresses_page.dart << 'DART'
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mes adresses')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _addressCard(
            'Domicile',
            'Cocody, pharmacie Mai',
            Icons.home,
            true,
          ),
          _addressCard(
            'Bureau',
            'Plateau, Rue du Commerce',
            Icons.work,
            false,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _addressCard(
      String label, String address, IconData icon, bool isDefault) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDefault ? AppColors.primary : Colors.transparent,
          width: isDefault ? 2 : 0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Défaut',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
DART

cat > lib/presentation/pages/profile/payments_page.dart << 'DART'
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Moyens de paiement')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(Icons.phone_android, 'Orange Money', '+225 07 ** ** ** 00',
              Color(0xFFFF7900)),
          _card(Icons.phone_android, 'MTN Mobile Money', '+225 05 ** ** ** 00',
              Color(0xFFFFCC00)),
          _card(Icons.credit_card, 'Visa •••• 4242', 'Expire 12/26',
              Color(0xFF2E7D32)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Ajouter', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _card(IconData icon, String label, String sub, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  sub,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
DART

cat > lib/presentation/pages/profile/settings_page.dart << 'DART'
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          _section('Général', [
            _tile('Langue', 'Français'),
            _tile('Devise', 'FCFA (XOF)'),
            _tile('Pays', 'Côte d\'Ivoire'),
          ]),
          _section('Sécurité', [
            _tile('Changer le mot de passe', ''),
            _tile('Authentification biométrique', 'Désactivée'),
          ]),
          _section('Données', [
            _tile('Télécharger mes données', ''),
            _tile('Supprimer mon compte', 'Action irréversible',
                color: Colors.red),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    const Divider(height: 1, indent: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(String title, String subtitle, {Color? color}) {
    return ListTile(
      title: Text(title, style: TextStyle(color: color)),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {},
    );
  }
}
DART

cat > lib/presentation/pages/profile/help_page.dart << 'DART'
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Aide & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _faq('Comment passer une commande ?',
              'Ajoutez des produits au panier, puis cliquez sur "Passer la commande".'),
          _faq('Quels sont les frais de livraison ?',
              'Livraison dynamique selon la zone et le poids. Récupération : 1000 FCFA.'),
          _faq('Comment suivre ma livraison ?',
              'Allez dans "Mes commandes" → cliquez sur la commande.'),
          _faq('Comment obtenir des points fidélité ?',
              'Chaque commande vous rapporte des points. 1 point = 10 FCFA.'),
          _faq('Puis-je annuler une commande ?',
              'Oui, tant qu\'elle n\'est pas en cours de livraison.'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chat, color: Colors.white),
            label: const Text('Contacter le support',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _faq(String q, String a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(q, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(a, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
DART

cat > lib/presentation/pages/profile/terms_page.dart << 'DART'
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Conditions d\'utilisation')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Text(
          '''Conditions Générales d'Utilisation — Flash Deals

1. ACCEPTATION
En utilisant l'application Flash Deals, vous acceptez les présentes conditions.

2. SERVICE
Flash Deals met en relation des clients avec des grandes surfaces proposant des articles en promotion ou liquidation.

3. COMMANDES
Toute commande est ferme et définitive après paiement.

4. LIVRAISON
Les frais de livraison sont calculés selon la zone et le poids. Le service de livraison est exclusivement assuré par Flash Deals.

5. PAIEMENT
Le paiement est 100% en ligne (Mobile Money, CB, Wallet).

6. RETOURS
Les articles périssables ne sont pas remboursables sauf en cas de vice caché.

7. RESPONSABILITÉ
Flash Deals ne peut être tenu responsable de l'indisponibilité des produits chez les partenaires.

8. DONNÉES PERSONNELLES
Vos données sont traitées conformément à notre politique de confidentialité.

Dernière mise à jour : 2025''',
          style: TextStyle(fontSize: 13, height: 1.6),
        ),
      ),
    );
  }
}
DART

cat > lib/presentation/pages/profile/privacy_page.dart << 'DART'
import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Confidentialité')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Text(
          '''Politique de Confidentialité — Flash Deals

1. DONNÉES COLLECTÉES
- Nom, téléphone, email
- Adresses de livraison
- Historique de commandes
- Localisation (pour la livraison)

2. UTILISATION
Vos données servent à :
- Traiter vos commandes
- Améliorer votre expérience
- Vous envoyer des notifications personnalisées

3. PARTAGE
Nous ne partageons PAS vos données avec des tiers, sauf obligation légale.

4. SÉCURITÉ
Vos données sont chiffrées et stockées de manière sécurisée.

5. VOS DROITS
Vous pouvez demander la suppression de vos données à tout moment.

6. CONTACT
privacy@flashdeals.ci

Dernière mise à jour : 2025''',
          style: TextStyle(fontSize: 13, height: 1.6),
        ),
      ),
    );
  }
}
DART

echo "✅ Profil amélioré + pages annexes créées"
