import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/admin_push_service.dart';
import '../../widgets/snackbars/app_snackbar.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() =>
      _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _sending = false;

  Future<void> _send() async {
    if (_titleCtrl.text.isEmpty || _bodyCtrl.text.isEmpty) {
      AppSnackbar.warning(context, 'Remplissez tous les champs');
      return;
    }

    setState(() => _sending = true);

    final ok = await AdminPushService.sendToAll(
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _sending = false);

    if (ok) {
      AppSnackbar.success(context, 'Notification envoyée');
      _titleCtrl.clear();
      _bodyCtrl.clear();
    } else {
      AppSnackbar.error(context, 'Erreur d\'envoi');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Admin • Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.red),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Envoie une notification push via OneSignal',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Titre *',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              hintText: 'Ex: Nouveau deal à Cocody',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Message *',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Ex: Lait Candia à -50% chez Carrefour Cocody !',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              label: Text(
                _sending ? 'Envoi...' : 'Envoyer à tous les clients',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
