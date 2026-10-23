import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../widgets/empty_states/empty_state.dart';
import '../../widgets/skeletons/shimmer_box.dart';
import '../../widgets/snackbars/app_snackbar.dart';

class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Mes adresses')),
        body: const EmptyState(
          icon: Icons.lock_outline,
          title: 'Connectez-vous',
          subtitle: 'Pour voir vos adresses',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mes adresses')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().streamAddresses(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: List.generate(
                  3, (_) => const Padding(padding: EdgeInsets.only(bottom: 12), child: ShimmerBox(height: 90))),
            );
          }

          final addresses = snapshot.data ?? [];
          if (addresses.isEmpty) {
            return const EmptyState(
              icon: Icons.location_off_outlined,
              title: 'Aucune adresse',
              subtitle: 'Ajoutez une adresse pour vos livraisons.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, i) =>
                _addressCard(context, addresses[i], uid),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddressForm(context, uid),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _addressCard(
      BuildContext context, Map<String, dynamic> a, String uid) {
    final id = a['id'] as String;
    final label = a['label'] as String? ?? 'Adresse';
    final fullAddress = a['fullAddress'] as String? ?? '';
    final zone = a['zone'] as String? ?? '';
    final isDefault = a['isDefault'] as bool? ?? false;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
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
                      fullAddress,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (zone.isNotEmpty)
                      Text(
                        'Zone : $zone',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!isDefault)
                TextButton.icon(
                  onPressed: () async {
                    await FirestoreService()
                        .setDefaultAddress(userId: uid, addressId: id);
                    if (context.mounted) {
                      AppSnackbar.success(context, 'Adresse par défaut');
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Définir par défaut'),
                ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _confirmDelete(context, uid, id, label),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddressForm(BuildContext context, String uid) {
    final labelCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final zoneCtrl = TextEditingController();
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
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Nouvelle adresse',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: labelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Label (Domicile, Bureau...)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Adresse complète',
                      hintText: 'Ex: Cocody, pharmacie Mai',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: zoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Zone',
                      hintText: 'Ex: Cocody',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (labelCtrl.text.isEmpty ||
                                  addressCtrl.text.isEmpty) {
                                AppSnackbar.warning(
                                    ctx, 'Remplissez tous les champs');
                                return;
                              }
                              setSheetState(() => saving = true);
                              await FirestoreService().addAddress(
                                userId: uid,
                                addressData: {
                                  'label': labelCtrl.text.trim(),
                                  'fullAddress': addressCtrl.text.trim(),
                                  'zone': zoneCtrl.text.trim(),
                                  'isDefault': false,
                                },
                              );
                              if (!context.mounted) return;
                              Navigator.pop(sheetContext);
                              AppSnackbar.success(
                                  context, 'Adresse ajoutée');
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
        );
      },
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
              await FirestoreService().deleteAddress(
                userId: uid,
                addressId: id,
              );
              if (context.mounted) {
                AppSnackbar.info(context, 'Adresse supprimée');
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
