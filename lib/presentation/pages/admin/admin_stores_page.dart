import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../widgets/empty_states/empty_state.dart';
import '../../widgets/skeletons/shimmer_box.dart';
import '../../widgets/snackbars/app_snackbar.dart';

class AdminStoresPage extends StatefulWidget {
  const AdminStoresPage({super.key});

  @override
  State<AdminStoresPage> createState() => _AdminStoresPageState();
}

class _AdminStoresPageState extends State<AdminStoresPage> {
  final _firestore = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Magasins'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showForm(),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestore.streamStores(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: List.generate(
                4,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: ShimmerBox(height: 90),
                ),
              ),
            );
          }

          final stores = snapshot.data ?? [];
          if (stores.isEmpty) {
            return const EmptyState(
              icon: Icons.store_outlined,
              title: 'Aucun magasin',
              subtitle: 'Ajoutez votre premier magasin partenaire.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stores.length,
            itemBuilder: (context, i) => _storeCard(stores[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Nouveau', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _storeCard(Map<String, dynamic> s) {
    final id = s['id'] as String;
    final name = s['name'] as String? ?? 'Magasin';
    final zone = s['zone'] as String? ?? '';
    final address = s['address'] as String? ?? '';
    final isOpen = s['isOpen'] as bool? ?? true;

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.store,
                color: Colors.teal, size: 24),
          ),
          const SizedBox(width: 14),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? Colors.green.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOpen ? 'Ouvert' : 'Fermé',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isOpen
                              ? Colors.green.shade800
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (zone.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          zone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                if (address.isNotEmpty)
                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
          // Actions
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _actionBtn(Icons.edit_outlined, AppColors.primary,
                  () => _showForm(existing: s)),
              const SizedBox(height: 4),
              _actionBtn(Icons.delete_outline, Colors.red,
                  () => _confirmDelete(id, name)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  void _showForm({Map<String, dynamic>? existing}) {
    final nameCtrl =
        TextEditingController(text: existing?['name'] as String? ?? '');
    final zoneCtrl =
        TextEditingController(text: existing?['zone'] as String? ?? '');
    final addressCtrl =
        TextEditingController(text: existing?['address'] as String? ?? '');
    bool isOpen = existing?['isOpen'] as bool? ?? true;
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
                Text(
                  existing == null
                      ? 'Nouveau magasin'
                      : 'Modifier le magasin',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    hintText: 'Ex: Carrefour Cocody',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.store),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: zoneCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Zone',
                    hintText: 'Ex: Cocody',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: addressCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Adresse',
                    hintText: 'Ex: Boulevard Latrille',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  value: isOpen,
                  onChanged: (v) => setSheetState(() => isOpen = v),
                  title: const Text('Magasin ouvert',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  activeColor: Colors.white,
                  activeTrackColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (nameCtrl.text.isEmpty) {
                              AppSnackbar.warning(ctx, 'Le nom est requis');
                              return;
                            }
                            setSheetState(() => saving = true);
                            try {
                              final data = {
                                'name': nameCtrl.text.trim(),
                                'zone': zoneCtrl.text.trim(),
                                'address': addressCtrl.text.trim(),
                                'isOpen': isOpen,
                              };
                              if (existing == null) {
                                await _firestore.addStore(data);
                              } else {
                                await _firestore.updateStore(
                                    existing['id'], data);
                              }
                              if (!mounted) return;
                              Navigator.pop(sheetContext);
                              AppSnackbar.success(
                                context,
                                existing == null
                                    ? 'Magasin créé'
                                    : 'Magasin modifié',
                              );
                            } catch (e) {
                              if (!mounted) return;
                              setSheetState(() => saving = false);
                              AppSnackbar.error(context, 'Erreur : $e');
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(
                            existing == null ? 'Créer' : 'Enregistrer',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer ?'),
        content: Text('Voulez-vous supprimer "$name" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _firestore.deleteStore(id);
              if (mounted) {
                AppSnackbar.success(context, 'Magasin supprimé');
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
