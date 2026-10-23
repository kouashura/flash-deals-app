import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product_model.dart';
import '../../widgets/empty_states/empty_state.dart';
import '../../widgets/skeletons/shimmer_box.dart';
import '../../widgets/snackbars/app_snackbar.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final _firestore = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Produits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nouveau produit',
            onPressed: () => _showForm(),
          ),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: _firestore.streamProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: List.generate(
                4,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: ShimmerBox(height: 110),
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Erreur : ${snapshot.error}'),
              ),
            );
          }

          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Aucun produit',
              subtitle: 'Ajoutez votre premier produit.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, i) => _productCard(products[i]),
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

  // ───────────────────────── CARTE PRODUIT ─────────────────────────
  Widget _productCard(ProductModel p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── IMAGE ───
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 70,
              height: 70,
              child: p.imageUrl.isEmpty
                  ? Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image,
                          color: Colors.grey, size: 28),
                    )
                  : Image.network(
                      p.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) =>
                          progress == null
                              ? child
                              : Container(
                                  color: Colors.grey.shade100,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                ),
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image,
                            color: Colors.grey, size: 28),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // ─── INFOS ───
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF14181F),
                  ),
                ),
                const SizedBox(height: 2),

                // Magasin
                Text(
                  p.storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 6),

                // Prix + Stock (ligne responsive)
                Row(
                  children: [
                    // Prix promo
                    Flexible(
                      child: Text(
                        Formatters.price(p.promoPrice),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Prix normal barré
                    if (p.normalPrice > p.promoPrice)
                      Flexible(
                        child: Text(
                          Formatters.price(p.normalPrice),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // Badges
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _badge(
                      '${p.stock} en stock',
                      p.isLowStock ? AppColors.error : Colors.blue,
                      Icons.inventory_2,
                    ),
                    if (p.expiryBadge != null)
                      _badge(
                        p.expiryBadge!,
                        AppColors.warning,
                        Icons.schedule,
                      ),
                    _badge(
                      '-${p.discountPercent.toStringAsFixed(0)}%',
                      AppColors.success,
                      Icons.local_offer,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ─── ACTIONS ───
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _actionBtn(
                Icons.edit_outlined,
                AppColors.primary,
                () => _showForm(existing: p),
              ),
              const SizedBox(height: 4),
              _actionBtn(
                Icons.delete_outline,
                Colors.red,
                () => _confirmDelete(p),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
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

  void _showForm({ProductModel? existing}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminProductFormPage(existing: existing),
      ),
    );
  }

  void _confirmDelete(ProductModel p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer ?'),
        content: Text('Voulez-vous vraiment supprimer "${p.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firestore.deleteProduct(p.id);
              if (mounted) {
                AppSnackbar.success(context, 'Produit supprimé');
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

// ══════════════════════════════════════════════════════════════════
// FORMULAIRE PRODUIT
// ══════════════════════════════════════════════════════════════════
class AdminProductFormPage extends StatefulWidget {
  final ProductModel? existing;
  const AdminProductFormPage({super.key, this.existing});

  @override
  State<AdminProductFormPage> createState() => _AdminProductFormPageState();
}

class _AdminProductFormPageState extends State<AdminProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirestoreService();
  final _uploadService = ImageUploadService();

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _normalPriceCtrl;
  late TextEditingController _promoPriceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _storeNameCtrl;
  late TextEditingController _weightCtrl;

  String _categoryId = '1';
  int _expiryDays = 7;
  String _imageUrl = '';
  bool _uploading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _normalPriceCtrl =
        TextEditingController(text: e?.normalPrice.toString() ?? '');
    _promoPriceCtrl =
        TextEditingController(text: e?.promoPrice.toString() ?? '');
    _stockCtrl = TextEditingController(text: e?.stock.toString() ?? '');
    _storeNameCtrl = TextEditingController(text: e?.storeName ?? '');
    _weightCtrl =
        TextEditingController(text: e?.weightKg.toString() ?? '1.0');
    _categoryId = e?.categoryId ?? '1';
    _imageUrl = e?.imageUrl ?? '';
    if (e != null) {
      _expiryDays = e.daysUntilExpiry > 0 ? e.daysUntilExpiry : 1;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _normalPriceCtrl.dispose();
    _promoPriceCtrl.dispose();
    _stockCtrl.dispose();
    _storeNameCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _uploading = true);
    final url = await _uploadService.pickAndUpload();
    if (!mounted) return;
    setState(() {
      _uploading = false;
      if (url != null) _imageUrl = url;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final product = ProductModel(
      id: widget.existing?.id ?? '',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      imageUrl: _imageUrl,
      categoryId: _categoryId,
      storeId: 's1',
      storeName: _storeNameCtrl.text.trim(),
      normalPrice: double.tryParse(_normalPriceCtrl.text) ?? 0,
      promoPrice: double.tryParse(_promoPriceCtrl.text) ?? 0,
      stock: int.tryParse(_stockCtrl.text) ?? 0,
      expiryDate: DateTime.now().add(Duration(days: _expiryDays)),
      isFlashDeal: true,
      weightKg: double.tryParse(_weightCtrl.text) ?? 1.0,
    );

    try {
      if (widget.existing == null) {
        await _firestore.addProduct(product);
      } else {
        await _firestore.updateProduct(product);
      }

      if (!mounted) return;
      AppSnackbar.success(
        context,
        widget.existing != null ? 'Produit modifié' : 'Produit créé',
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.error(context, 'Erreur : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier le produit' : 'Nouveau produit'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── IMAGE ───
            Center(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _uploading ? null : _pickImage,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _imageUrl.isEmpty
                            ? Colors.grey.shade300
                            : AppColors.primary,
                        width: 2,
                      ),
                    ),
                    child: _uploading
                        ? const Center(child: CircularProgressIndicator())
                        : _imageUrl.isEmpty
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate,
                                      size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Ajouter une image',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey)),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(_imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image,
                                            size: 48, color: Colors.grey)),
                              ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ─── CHAMPS ───
            _field(_nameCtrl, 'Nom du produit *', Icons.shopping_bag),
            const SizedBox(height: 14),
            _field(_descCtrl, 'Description', Icons.description, maxLines: 3),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                    child: _field(_normalPriceCtrl, 'Prix normal *',
                        Icons.attach_money,
                        keyboard: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(
                    child: _field(_promoPriceCtrl, 'Prix promo *',
                        Icons.local_offer,
                        keyboard: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                    child: _field(_stockCtrl, 'Stock *', Icons.inventory,
                        keyboard: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(
                    child: _field(_weightCtrl, 'Poids (kg) *', Icons.scale,
                        keyboard: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 14),

            _field(_storeNameCtrl, 'Magasin *', Icons.store),
            const SizedBox(height: 14),

            // Catégorie
            DropdownButtonFormField<String>(
              value: _categoryId,
              decoration: _decoration('Catégorie', Icons.category),
              items: const [
                DropdownMenuItem(value: '1', child: Text('🥛 Laitier')),
                DropdownMenuItem(value: '2', child: Text('🥩 Viande')),
                DropdownMenuItem(
                    value: '3', child: Text('🍞 Boulangerie')),
                DropdownMenuItem(value: '4', child: Text('🥤 Boissons')),
                DropdownMenuItem(value: '5', child: Text('🧴 Hygiène')),
                DropdownMenuItem(value: '6', child: Text('🥫 Épicerie')),
              ],
              onChanged: (v) => setState(() => _categoryId = v ?? '1'),
            ),
            const SizedBox(height: 14),

            // Date de péremption
            DropdownButtonFormField<int>(
              value: _expiryDays,
              decoration: _decoration('Expire dans', Icons.schedule),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 jour (J-1)')),
                DropdownMenuItem(value: 2, child: Text('2 jours')),
                DropdownMenuItem(value: 3, child: Text('3 jours (J-3)')),
                DropdownMenuItem(value: 5, child: Text('5 jours')),
                DropdownMenuItem(value: 7, child: Text('7 jours (J-7)')),
                DropdownMenuItem(value: 14, child: Text('14 jours')),
                DropdownMenuItem(value: 30, child: Text('30 jours')),
              ],
              onChanged: (v) => setState(() => _expiryDays = v ?? 7),
            ),
            const SizedBox(height: 24),

            // ─── BOUTON ───
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: (_uploading || _saving) ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check, color: Colors.white),
                label: Text(
                  _saving
                      ? 'Enregistrement...'
                      : (isEdit ? 'Enregistrer' : 'Créer le produit'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: _decoration(label, icon),
      validator: (v) {
        if (label.contains('*') && (v == null || v.trim().isEmpty)) {
          return 'Champ obligatoire';
        }
        return null;
      },
    );
  }
}
