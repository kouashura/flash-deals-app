import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/empty_states/empty_state.dart';
import '../../widgets/skeletons/shimmer_box.dart';
import '../../widgets/snackbars/app_snackbar.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Mes favoris')),
        body: const EmptyState(
          icon: Icons.lock_outline,
          title: 'Connectez-vous',
          subtitle: 'Pour voir vos favoris',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mes favoris')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().streamFavorites(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: List.generate(
                  4, (_) => const Padding(padding: EdgeInsets.only(bottom: 12), child: ShimmerBox(height: 90))),
            );
          }

          final favorites = snapshot.data ?? [];
          if (favorites.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'Aucun favori',
              subtitle:
                  'Ajoutez des produits à vos favoris\npour les retrouver ici.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, i) {
              final f = favorites[i];
              return _favoriteCard(context, f, uid);
            },
          );
        },
      ),
    );
  }

  Widget _favoriteCard(
      BuildContext context, Map<String, dynamic> f, String uid) {
    final id = f['id'] as String;
    final name = f['name'] as String? ?? 'Produit';
    final imageUrl = f['imageUrl'] as String? ?? '';
    final promoPrice = (f['promoPrice'] as num?)?.toDouble() ?? 0;
    final normalPrice = (f['normalPrice'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 70,
              height: 70,
              color: Colors.grey.shade200,
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image, color: Colors.grey))
                  : const Icon(Icons.image, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      Formatters.price(promoPrice),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (normalPrice > promoPrice)
                      Text(
                        Formatters.price(normalPrice),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.favorite,
                    color: Colors.red, size: 22),
                onPressed: () async {
                  await FirestoreService().toggleFavorite(
                    userId: uid,
                    productId: id,
                    productData: f,
                  );
                  if (context.mounted) {
                    AppSnackbar.info(context, 'Retiré des favoris');
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward,
                    color: AppColors.primary, size: 20),
                onPressed: () => context.push('/product/$id'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
