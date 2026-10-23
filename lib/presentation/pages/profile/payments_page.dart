import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../widgets/empty_states/empty_state.dart';
import '../../widgets/skeletons/shimmer_box.dart';
import '../../widgets/snackbars/app_snackbar.dart';

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Moyens de paiement')),
        body: const EmptyState(
          icon: Icons.lock_outline,
          title: 'Connectez-vous',
          subtitle: 'Pour voir vos moyens de paiement',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Moyens de paiement')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().streamPaymentMethods(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: List.generate(
                  3, (_) => const Padding(padding: EdgeInsets.only(bottom: 12), child: ShimmerBox(height: 80))),
            );
          }

          final methods = snapshot.data ?? [];
          if (methods.isEmpty) {
            return const EmptyState(
              icon: Icons.credit_card_off_outlined,
              title: 'Aucun moyen de paiement',
              subtitle: 'Ajoutez une carte ou un compte Mobile Money.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: methods.length,
            itemBuilder: (context, i) =>
                _methodCard(context, methods[i], uid),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMethodPicker(context, uid),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _methodCard(
      BuildContext context, Map<String, dynamic> m, String uid) {
    final id = m['id'] as String;
    final type = m['type'] as String? ?? 'card';
    final label = m['label'] as String? ?? '';
    final number = m['number'] as String? ?? '';
    final isDefault = m['isDefault'] as bool? ?? false;

    final (icon, color) = _iconFor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDefault ? AppColors.primary : Colors.transparent,
          width: isDefault ? 2 : 0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
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
                const SizedBox(height: 4),
                Text(
                  number,
                  style:
                      const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () => _confirmDelete(context, uid, id, label),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _iconFor(String type) {
    switch (type) {
      case 'orange':
        return (Icons.phone_android, const Color(0xFFFF7900));
      case 'mtn':
        return (Icons.phone_android, const Color(0xFFFFCC00));
      case 'moov':
        return (Icons.phone_android, const Color(0xFF0066CC));
      case 'wave':
        return (Icons.water_drop, const Color(0xFF1DC4FF));
      case 'card':
        return (Icons.credit_card, const Color(0xFF2E7D32));
      default:
        return (Icons.payment, Colors.grey);
    }
  }

  void _showMethodPicker(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Choisir un type',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _pickTile(sheetContext, uid, 'orange', 'Orange Money', '🟠'),
            _pickTile(sheetContext, uid, 'mtn', 'MTN Mobile Money', '🟡'),
            _pickTile(sheetContext, uid, 'moov', 'Moov Money', '🔵'),
            _pickTile(sheetContext, uid, 'wave', 'Wave', '🌊'),
            _pickTile(sheetContext, uid, 'card', 'Carte bancaire', '💳'),
          ],
        ),
      ),
    );
  }

  Widget _pickTile(BuildContext sheetContext, String uid, String type,
      String label, String emoji) {
    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 24)),
      title: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pop(sheetContext);
        _showAddForm(
          // Utilise le context parent via la clé
          (sheetContext as Element).findAncestorStateOfType<State>()!.context,
          uid,
          type,
          label,
        );
      },
    );
  }

  void _showAddForm(
      BuildContext context, String uid, String type, String label) {
    final numberCtrl = TextEditingController();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Ajouter $label',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                TextField(
                  controller: numberCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: type == 'card'
                        ? 'Numéro de carte'
                        : 'Numéro de téléphone',
                    hintText: type == 'card'
                        ? '4242 4242 4242 4242'
                        : '+225 07 XX XX XX XX',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (numberCtrl.text.isEmpty) {
                              AppSnackbar.warning(
                                  ctx, 'Remplissez le numéro');
                              return;
                            }
                            setSheetState(() => saving = true);
                            await FirestoreService().addPaymentMethod(
                              userId: uid,
                              paymentData: {
                                'type': type,
                                'label': label,
                                'number': numberCtrl.text.trim(),
                                'isDefault': false,
                              },
                            );
                            if (!context.mounted) return;
                            Navigator.pop(sheetContext);
                            AppSnackbar.success(
                                context, '$label ajouté');
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Ajouter',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, String uid, String id, String label) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer ?'),
        content: Text('Voulez-vous supprimer "$label" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await FirestoreService().deletePaymentMethod(
                userId: uid,
                paymentId: id,
              );
              if (context.mounted) {
                AppSnackbar.info(context, 'Moyen de paiement supprimé');
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
