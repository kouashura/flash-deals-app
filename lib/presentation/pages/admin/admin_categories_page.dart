import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../widgets/empty_states/empty_state.dart';
import '../../widgets/skeletons/shimmer_box.dart';
import '../../widgets/snackbars/app_snackbar.dart';

class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  final _firestore = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Catégories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showForm(),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestore.streamCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: List.generate(
                4,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: ShimmerBox(height: 72),
                ),
              ),
            );
          }

          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return const EmptyState(
              icon: Icons.category_outlined,
              title: 'Aucune catégorie',
              subtitle: 'Ajoutez votre première catégorie.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, i) => _categoryCard(categories[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Nouvelle', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _categoryCard(Map<String, dynamic> c) {
    final id = c['id'] as String;
    final name = c['name'] as String? ?? 'Catégorie';
    final emoji = c['emoji'] as String? ?? '📦';

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
        children: [
          // Emoji
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                FutureBuilder<int>(
                  future: _firestore.countProductsInCategory(name),
                  builder: (context, snap) {
                    final count = snap.data ?? 0;
                    return Text(
                      '$count produits',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Actions
          _actionBtn(Icons.edit_outlined, AppColors.primary,
              () => _showForm(existing: c)),
          const SizedBox(width: 6),
          _actionBtn(Icons.delete_outline, Colors.red,
              () => _confirmDelete(id, name)),
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
    final emojiCtrl =
        TextEditingController(text: existing?['emoji'] as String? ?? '📦');
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
                      ? 'Nouvelle catégorie'
                      : 'Modifier la catégorie',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                // Nom
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    hintText: 'Ex: Laitier',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 14),
                // Emoji
                TextField(
                  controller: emojiCtrl,
                  textAlign: TextAlign.center,
                  maxLength: 2,
                  style: const TextStyle(fontSize: 28),
                  decoration: const InputDecoration(
                    labelText: 'Emoji',
                    hintText: '🥛',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 8),
                // Suggestions d'emojis
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    '🥛', '🥩', '🍞', '🥤', '🧴', '🥫',
                    '🍕', '🍰', '🧀', '🍎', '🍖', '🧊',
                  ]
                      .map((e) => GestureDetector(
                            onTap: () => emojiCtrl.text = e,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(e,
                                  style: const TextStyle(fontSize: 22)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
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
                                'emoji': emojiCtrl.text.isEmpty
                                    ? '📦'
                                    : emojiCtrl.text,
                              };
                              if (existing == null) {
                                await _firestore.addCategory(data);
                              } else {
                                await _firestore.updateCategory(
                                    existing['id'], data);
                              }
                              if (!mounted) return;
                              Navigator.pop(sheetContext);
                              AppSnackbar.success(
                                context,
                                existing == null
                                    ? 'Catégorie créée'
                                    : 'Catégorie modifiée',
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
              await _firestore.deleteCategory(id);
              if (mounted) {
                AppSnackbar.success(context, 'Catégorie supprimée');
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
