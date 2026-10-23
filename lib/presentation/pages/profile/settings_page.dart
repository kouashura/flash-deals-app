import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/services/theme_service.dart';
import '../../widgets/snackbars/app_snackbar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Préférences
  String _language = 'fr';
  String _currency = 'FCFA';
  bool _notifications = true;
  bool _dealAlerts = true;
  bool _sound = true;
  bool _biometric = false;
  String _version = '1.0.0';

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _language = await PreferencesService.getLanguage();
    _currency = await PreferencesService.getCurrency();
    _notifications = await PreferencesService.getNotifications();
    _dealAlerts = await PreferencesService.getDealAlerts();
    _sound = await PreferencesService.getSound();
    _biometric = await PreferencesService.getBiometric();

    try {
      final info = await PackageInfo.fromPlatform();
      _version = '${info.version} (${info.buildNumber})';
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _changePassword() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        AppSnackbar.success(
            context, 'Email de réinitialisation envoyé à $email');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Erreur : $e');
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Supprimer le compte ?',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        content: const Text(
          'Cette action est IRRÉVERSIBLE.\n'
          'Toutes vos données seront perdues : commandes, favoris, points fidélité...',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseAuth.instance.currentUser?.delete();
      if (mounted) {
        AppSnackbar.success(context, 'Compte supprimé');
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
            context, 'Reconnectez-vous puis réessayez');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Paramètres')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ═══ GÉNÉRAL ═══
          _section('🌍 Général', [
            _dropdownTile(
              icon: Icons.language,
              title: 'Langue',
              value: _language,
              options: {
                'fr': 'Français',
                'en': 'English',
              },
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _language = v);
                await PreferencesService.setLanguage(v);
                if (mounted) {
                  AppSnackbar.info(context, 'Langue modifiée');
                }
              },
            ),
            _dropdownTile(
              icon: Icons.attach_money,
              title: 'Devise',
              value: _currency,
              options: {
                'FCFA': 'FCFA (XOF)',
                'EUR': 'Euro (€)',
                'USD': 'Dollar (\$)',
              },
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _currency = v);
                await PreferencesService.setCurrency(v);
                if (mounted) {
                  AppSnackbar.info(context, 'Devise modifiée');
                }
              },
            ),
          ]),

          // ═══ APPARENCE ═══
          _section('🎨 Apparence', [
            _switchTile(
              icon: Icons.dark_mode_outlined,
              title: 'Mode sombre',
              subtitle: 'Confort visuel la nuit',
              value: sl<ThemeService>().isDark,
              onChanged: (v) async {
                await sl<ThemeService>().toggle(v);
                setState(() {});
              },
            ),
          ]),

          // ═══ NOTIFICATIONS ═══
          _section('🔔 Notifications', [
            _switchTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications push',
              subtitle: 'Recevoir les notifications',
              value: _notifications,
              onChanged: (v) async {
                setState(() => _notifications = v);
                await PreferencesService.setNotifications(v);
              },
            ),
            _switchTile(
              icon: Icons.local_offer_outlined,
              title: 'Alertes deals',
              subtitle: 'Nouveaux deals près de vous',
              value: _dealAlerts,
              onChanged: (v) async {
                setState(() => _dealAlerts = v);
                await PreferencesService.setDealAlerts(v);
              },
            ),
            _switchTile(
              icon: Icons.volume_up_outlined,
              title: 'Sons',
              subtitle: 'Sons de notification',
              value: _sound,
              onChanged: (v) async {
                setState(() => _sound = v);
                await PreferencesService.setSound(v);
              },
            ),
          ]),

          // ═══ SÉCURITÉ ═══
          _section('🔒 Sécurité', [
            _actionTile(
              icon: Icons.lock_outline,
              title: 'Changer le mot de passe',
              subtitle: 'Recevoir un email de réinitialisation',
              onTap: _changePassword,
            ),
            _switchTile(
              icon: Icons.fingerprint,
              title: 'Biométrie',
              subtitle: 'Empreinte ou Face ID',
              value: _biometric,
              onChanged: (v) async {
                setState(() => _biometric = v);
                await PreferencesService.setBiometric(v);
                if (v && mounted) {
                  AppSnackbar.info(
                      context, 'Fonctionnalité bientôt disponible');
                }
              },
            ),
          ]),

          // ═══ DONNÉES ═══
          _section('📊 Données', [
            _actionTile(
              icon: Icons.download_outlined,
              title: 'Télécharger mes données',
              subtitle: 'Export de vos informations',
              onTap: () {
                AppSnackbar.info(context, 'Bientôt disponible');
              },
            ),
            _actionTile(
              icon: Icons.delete_outline,
              title: 'Supprimer mon compte',
              subtitle: 'Action irréversible',
              color: Colors.red,
              onTap: _deleteAccount,
            ),
          ]),

          // ═══ À PROPOS ═══
          _section('📱 À propos', [
            _infoTile(
              icon: Icons.info_outline,
              title: 'Version',
              value: _version,
            ),
            _actionTile(
              icon: Icons.gavel,
              title: 'Conditions d\'utilisation',
              subtitle: 'Lire les CGU',
              onTap: () => context.push('/profile/terms'),
            ),
            _actionTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Confidentialité',
              subtitle: 'Politique de confidentialité',
              onTap: () => context.push('/profile/privacy'),
            ),
            _actionTile(
              icon: Icons.help_outline,
              title: 'Aide & support',
              subtitle: 'FAQ, nous contacter',
              onTap: () => context.push('/profile/help'),
            ),
          ]),

          const SizedBox(height: 24),

          // ═══ FOOTER ═══
          const Center(
            child: Text(
              'Flash Deals Abidjan',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Fait avec ❤️ en Côte d\'Ivoire',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // WIDGETS
  // ═══════════════════════════════════════
  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey,
              ),
            ),
          ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 60,
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

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
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
                      fontSize: 12, color: Colors.grey),
                ),
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

  Widget _dropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required Map<String, String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            isDense: true,
            items: options.entries
                .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(
                        e.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
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
                color: (color ?? AppColors.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: color ?? AppColors.primary, size: 18),
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
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
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
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
