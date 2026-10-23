import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/services/admin_auth_service.dart';
import '../../../core/services/image_upload_service.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/snackbars/app_snackbar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _aboutTapCount = 0;
  bool _avatarLoaded = false;
  DateTime? _lastAboutTap;

  bool _notificationsEnabled = true;
  String? _avatarUrl;
  final _uploadService = ImageUploadService();

  Color get _primaryDark => Color.lerp(AppColors.primary, Colors.black, 0.28)!;

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

  InputDecoration _fieldDecoration(String label, IconData icon,
      {Widget? suffix}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF6F7F9),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(AppColors.primary, 1.6),
    );
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
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text(
                      'Accès administrateur',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Réservé au personnel autorisé.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ctrl,
                    obscureText: obscure,
                    autofocus: true,
                    decoration: _fieldDecoration(
                      'Mot de passe',
                      Icons.lock_outline_rounded,
                      suffix: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () =>
                            setStateDialog(() => obscure = !obscure),
                      ),
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () {
                    if (AdminAuthService.verifyPassword(ctrl.text)) {
                      Navigator.pop(dialogContext);
                      context.push('/admin');
                    } else {
                      AppSnackbar.error(context, 'Mot de passe incorrect');
                      ctrl.clear();
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Valider'),
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
    if (!_avatarLoaded) {
      _avatarLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null && mounted) {
          try {
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();
            final url = doc.data()?['avatarUrl'] as String?;
            if (url != null && url.isNotEmpty && mounted) {
              setState(() => _avatarUrl = url);
              debugPrint('✅ Avatar chargé depuis Firestore');
            }
          } catch (e) {
            debugPrint('❌ Erreur chargement avatar: $e');
          }
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Mon profil',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
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

  Widget _buildNotConnected(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, _primaryDark],
              ),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      size: 52, color: Colors.white),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Bienvenue sur Flash Deals',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connectez-vous pour accéder à votre profil.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _benefit(Icons.local_shipping_outlined, 'Suivez vos commandes',
                    'Gardez un œil sur chaque livraison.'),
                const SizedBox(height: 12),
                _benefit(Icons.card_giftcard_rounded,
                    'Cumulez des points fidélité',
                    'Transformez vos achats en avantages.'),
                const SizedBox(height: 12),
                _benefit(Icons.favorite_border_rounded, 'Gardez vos favoris',
                    'Retrouvez vos deals préférés partout.'),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => context.push('/login'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Se connecter',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                          color: AppColors.primary, width: 1.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Créer un compte',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.card_giftcard_rounded,
                          color: AppColors.primary, size: 16),
                      SizedBox(width: 8),
                      Text(
                        '50 points offerts à l\'inscription',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefit(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _softShadow,
      ),
      child: Row(
        children: [
          _iconBox(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnected(BuildContext context, AuthAuthenticated state) {
    final user = state.user;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 52),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildHeader(context, user),
              Positioned(
                left: 16,
                right: 16,
                bottom: -44,
                child: _buildStatsCard(user),
              ),
            ],
          ),
        ),
        // 🚚 BOUTON DEVENIR LIVREUR
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFFFF9800)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () => context.push('/courier/login'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delivery_dining,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Devenir livreur',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Gagnez de l\'argent en livrant',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
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

        _menuSection('Mon compte', [
          _menuTile(
            Icons.receipt_long_outlined,
            'Mes commandes',
            'Suivre mes livraisons',
            () => context.push('/orders'),
          ),
          _menuTile(
            Icons.account_balance_wallet_outlined,
            'Mon Deals Cash',
            'Portefeuille, solde et recharge',
            () => context.push('/wallet'),
          ),
          _menuTile(
            Icons.favorite_border_rounded,
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
            Icons.credit_card_rounded,
            'Moyens de paiement',
            'Mobile Money, CB, Wallet',
            () => context.push('/profile/payments'),
          ),
        ]),
        _menuSection('Préférences', [
          _switchTile(
            Icons.notifications_none_rounded,
            'Notifications',
            'Recevoir les alertes deals',
            _notificationsEnabled,
            (v) => setState(() => _notificationsEnabled = v),
          ),
          _switchTile(
            Icons.dark_mode_outlined,
            'Mode sombre',
            'Confort visuel la nuit',
            sl<ThemeService>().isDark,
            (v) async {
              await sl<ThemeService>().toggle(v);
              if (mounted) setState(() {});
            },
          ),
          _menuTile(
            Icons.settings_outlined,
            'Paramètres',
            'Langue, devise, sécurité',
            () => context.push('/profile/settings'),
          ),
        ]),
        _menuSection('Support', [
          _menuTile(
            Icons.help_outline_rounded,
            'Aide & support',
            'FAQ, contact',
            () => context.push('/profile/help'),
          ),
          _menuTile(
            Icons.gavel_rounded,
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
            Icons.info_outline_rounded,
            'À propos',
            'Version 1.0.0',
            _handleAboutTap,
          ),
          if (kDebugMode) ...[
            _menuTile(
              Icons.map,
              'Test Map',
              'Voir la carte OpenStreetMap',
              () => context.push('/map-picker'),
            ),
            _menuTile(
              Icons.cloud_upload_outlined,
              'Test Upload',
              'Uploader une image (temporaire)',
              () => context.push('/test-upload'),
            ),
          ],
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: TextButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded, color: Colors.red),
              label: const Text(
                'Se déconnecter',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 64),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, _primaryDark],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () async {
                    final url = await _uploadService.pickAndUpload();
                    if (!mounted) return;
                    if (url != null) {
                      setState(() => _avatarUrl = url);

                      try {
                        final userId = FirebaseAuth.instance.currentUser?.uid;
                        if (userId != null) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .update({'avatarUrl': url});
                          debugPrint('✅ Avatar sauvegardé dans Firestore');
                        }
                      } catch (e) {
                        debugPrint('❌ Erreur sauvegarde avatar: $e');
                      }

                      if (!mounted) return;
                      AppSnackbar.success(context, 'Avatar mis à jour');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: const Color(0xFFF1F2F4),
                      backgroundImage:
                          _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                      child: _avatarUrl == null
                          ? Text(
                              user.fullName.isNotEmpty
                                  ? user.fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 36,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            user.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              if (user.phone.isNotEmpty)
                _contactChip(Icons.phone_rounded, user.phone),
              if (user.email.isNotEmpty)
                _contactChip(Icons.mail_outline_rounded, user.email),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _editProfile(context, user),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Modifier mon profil'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.7)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(user) {
    final stats = [
      _Stat(Icons.receipt_long_rounded, '12', 'Commandes', Colors.blue),
      _Stat(Icons.card_giftcard_rounded, '${user.loyaltyPoints}', 'Points',
          AppColors.primary),
      _Stat(Icons.savings_rounded, '24K', 'Économies', AppColors.success),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (int i = 0; i < stats.length; i++) ...[
              Expanded(child: _statItem(stats[i])),
              if (i < stats.length - 1)
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.grey.shade200,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statItem(_Stat s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: s.color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(s.icon, color: s.color, size: 18),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            s.value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          s.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  List<BoxShadow> get _softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  Widget _iconBox(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }

  Widget _menuSection(String title, List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: _softShadow,
            ),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  items[i],
                  if (i < items.length - 1)
                    Divider(
                      height: 1,
                      indent: 68,
                      endIndent: 14,
                      color: Colors.grey.shade200,
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
            _iconBox(icon),
            const SizedBox(width: 14),
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
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 22),
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
          _iconBox(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _editProfile(BuildContext context, user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final emailCtrl = TextEditingController(text: user.email);
    final phoneCtrl = TextEditingController(text: user.phone);
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Modifier mon profil',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mettez à jour vos informations personnelles.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      _fieldDecoration('Nom complet', Icons.person_outline),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration:
                      _fieldDecoration('Téléphone', Icons.phone_outlined),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _fieldDecoration('Email', Icons.mail_outline),
                ),
                const SizedBox(height: 24),
                StatefulBuilder(
                  builder: (ctx, setSheetState) => SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setSheetState(() => saving = true);
                              try {
                                context.read<AuthBloc>().add(
                                      UpdateProfile(
                                        fullName: nameCtrl.text.trim(),
                                        phone: phoneCtrl.text.trim(),
                                      ),
                                    );
                                await Future.delayed(
                                    const Duration(milliseconds: 500));
                                if (!mounted) return;
                                Navigator.pop(sheetContext);
                                AppSnackbar.success(
                                    context, 'Profil mis à jour');
                              } catch (e) {
                                if (!mounted) return;
                                AppSnackbar.error(context, 'Erreur : $e');
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Enregistrer',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.logout_rounded, color: Colors.red, size: 26),
        ),
        title: const Text(
          'Se déconnecter ?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Text(
          'Vous devrez vous reconnecter pour accéder à votre compte.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(const LogoutRequested());
              context.go('/home');
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}

class _Stat {
  const _Stat(this.icon, this.value, this.label, this.color);
  final IconData icon;
  final String value;
  final String label;
  final Color color;
}
