import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product_model.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../widgets/snackbars/app_snackbar.dart';

class ProductDetailsPage extends StatefulWidget {
  final String productId;
  const ProductDetailsPage({super.key, required this.productId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final _firestore = FirestoreService();
  ProductModel? _product;
  bool _loading = true;
  String? _error;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final product = await _firestore.getProduct(widget.productId);
      if (product == null) {
        throw Exception('Produit introuvable');
      }
      if (!mounted) return;

      // Vérifier si le produit est en favori
      final user = FirebaseAuth.instance.currentUser;
      bool isFav = false;
      if (user != null) {
        try {
          isFav = await _firestore.isFavorite(
            userId: user.uid,
            productId: widget.productId,
          );
        } catch (_) {}
      }

      setState(() {
        _product = product;
        _isFavorite = isFav;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar.warning(context, 'Connectez-vous pour ajouter aux favoris');
      return;
    }

    try {
      await _firestore.toggleFavorite(
        userId: user.uid,
        productId: widget.productId,
        productData: {
          'name': _product!.name,
          'imageUrl': _product!.imageUrl,
          'promoPrice': _product!.promoPrice,
          'normalPrice': _product!.normalPrice,
          'storeName': _product!.storeName,
          'categoryId': _product!.categoryId,
        },
      );

      setState(() => _isFavorite = !_isFavorite);

      if (!mounted) return;
      AppSnackbar.success(
        context,
        _isFavorite ? 'Ajouté aux favoris' : 'Retiré des favoris',
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Erreur : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Chargement...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _product == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Produit introuvable',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Réessayer',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final p = _product!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          // ❤️ Bouton favori
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            tooltip: _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: ListView(
        children: [
          // IMAGE
          Container(
            height: 250,
            width: double.infinity,
            color: Colors.grey.shade200,
            child: p.imageUrl.isNotEmpty
                ? Image.network(
                    p.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image,
                          size: 80, color: Colors.grey),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.image, size: 80, color: Colors.grey),
                  ),
          ),

          // INFOS
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BADGES
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${p.discountPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (p.expiryBadge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.expiryBadge!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // NOM
                Text(
                  p.name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),

                // MAGASIN
                Row(
                  children: [
                    const Icon(Icons.store, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(p.storeName,
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 12),

                // PRIX
                Row(
                  children: [
                    Text(
                      Formatters.price(p.promoPrice),
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      Formatters.price(p.normalPrice),
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // STOCK
                if (p.isLowStock)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '⚠️ Plus que ${p.stock} en stock !',
                      style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 20),

                // DESCRIPTION
                const Text('Description',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  p.description.isEmpty
                      ? 'Aucune description disponible.'
                      : p.description,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // BOUTON AJOUTER AU PANIER
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<CartBloc>().add(AddToCart(p));
                      AppSnackbar.success(
                          context, '${p.name} ajouté au panier');
                    },
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    label: const Text('Ajouter au panier',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
