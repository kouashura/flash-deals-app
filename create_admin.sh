#!/bin/bash
echo "👨‍💼 Création du back-office admin..."

mkdir -p lib/presentation/pages/admin/widgets

# ============================================================
# WIDGET: ADMIN STAT CARD
# ============================================================
cat > lib/presentation/pages/admin/widgets/admin_stat_card.dart << 'DART'
import 'package:flutter/material.dart';

class AdminStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const AdminStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
DART

# ============================================================
# WIDGET: ADMIN MENU TILE
# ============================================================
cat > lib/presentation/pages/admin/widgets/admin_menu_tile.dart << 'DART'
import 'package:flutter/material.dart';

class AdminMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const AdminMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
DART

# ============================================================
# PAGE: ADMIN DASHBOARD
# ============================================================
cat > lib/presentation/pages/admin/admin_dashboard_page.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import 'widgets/admin_stat_card.dart';
import 'widgets/admin_menu_tile.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin • Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Quitter admin',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // === BIENVENUE ===
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFFFF9800)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.admin_panel_settings,
                      color: AppColors.primary, size: 28),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour Admin 👋',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Voici l\'activité du jour',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // === STATS ===
          const Text(
            '📊 Statistiques',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              AdminStatCard(
                icon: Icons.shopping_bag,
                label: 'Commandes',
                value: '24',
                color: AppColors.primary,
                onTap: () => context.push('/admin/orders'),
              ),
              AdminStatCard(
                icon: Icons.attach_money,
                label: 'Revenus (FCFA)',
                value: '158K',
                color: AppColors.success,
              ),
              AdminStatCard(
                icon: Icons.inventory_2,
                label: 'Produits',
                value: '6',
                color: Colors.blue,
                onTap: () => context.push('/admin/products'),
              ),
              AdminStatCard(
                icon: Icons.people,
                label: 'Clients',
                value: '132',
                color: Colors.purple,
                onTap: () => context.push('/admin/users'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // === GESTION ===
          const Text(
            '🛠️ Gestion',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 10),
          AdminMenuTile(
            icon: Icons.shopping_bag,
            title: 'Commandes',
            subtitle: 'Voir et mettre à jour les commandes',
            color: AppColors.primary,
            onTap: () => context.push('/admin/orders'),
          ),
          const SizedBox(height: 10),
          AdminMenuTile(
            icon: Icons.inventory_2,
            title: 'Produits',
            subtitle: 'Ajouter, modifier, supprimer',
            color: Colors.blue,
            onTap: () => context.push('/admin/products'),
          ),
          const SizedBox(height: 10),
          AdminMenuTile(
            icon: Icons.category,
            title: 'Catégories',
            subtitle: 'Gérer les catégories',
            color: Colors.orange,
            onTap: () => context.push('/admin/categories'),
          ),
          const SizedBox(height: 10),
          AdminMenuTile(
            icon: Icons.store,
            title: 'Magasins',
            subtitle: 'Grandes surfaces partenaires',
            color: Colors.teal,
            onTap: () => context.push('/admin/stores'),
          ),
          const SizedBox(height: 10),
          AdminMenuTile(
            icon: Icons.people,
            title: 'Utilisateurs',
            subtitle: 'Voir les clients inscrits',
            color: Colors.purple,
            onTap: () => context.push('/admin/users'),
          ),
          const SizedBox(height: 10),
          AdminMenuTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Envoyer une notification push',
            color: Colors.red,
            onTap: () => context.push('/admin/notifications'),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
DART

# ============================================================
# PAGE: ADMIN PRODUCTS (liste + CRUD)
# ============================================================
cat > lib/presentation/pages/admin/admin_products_page.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product_model.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final List<ProductModel> _products = [
    ProductModel(
      id: '1', name: 'Lait Candia 1L', description: '',
      imageUrl: '', categoryId: '1', storeId: 's1',
      storeName: 'Carrefour Cocody',
      normalPrice: 1200, promoPrice: 600, stock: 3,
      expiryDate: DateTime.now().add(const Duration(days: 3)),
      isFlashDeal: true, rating: 4.5, reviewCount: 12, weightKg: 1.0,
    ),
    ProductModel(
      id: '2', name: 'Yaourt Activia x4', description: '',
      imageUrl: '', categoryId: '1', storeId: 's2',
      storeName: 'Prosuma Plateau',
      normalPrice: 2500, promoPrice: 1500, stock: 8,
      expiryDate: DateTime.now().add(const Duration(days: 5)),
      isFlashDeal: true, rating: 4.2, reviewCount: 8, weightKg: 0.5,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin • Produits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nouveau produit',
            onPressed: () => _showProductForm(),
          ),
        ],
      ),
      body: _products.isEmpty
          ? const Center(child: Text('Aucun produit'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _products.length,
              itemBuilder: (context, i) => _buildCard(_products[i], i),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductForm(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouveau', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildCard(ProductModel p, int index) {
    final expired = p.daysUntilExpiry < 0;
    final lowStock = p.isLowStock;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.storeName,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          Formatters.price(p.promoPrice),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          Formatters.price(p.normalPrice),
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
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primary),
                onPressed: () => _showProductForm(existing: p, index: index),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDelete(index),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Badges
          Wrap(
            spacing: 6,
            children: [
              _badge('Stock: ${p.stock}', lowStock ? Colors.orange : Colors.blue),
              _badge('${p.weightKg} kg', Colors.purple),
              if (expired)
                _badge('Expiré', Colors.red)
              else if (p.expiryBadge != null)
                _badge(p.expiryBadge!, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showProductForm({ProductModel? existing, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminProductFormPage(
          existing: existing,
          onSave: (p) {
            setState(() {
              if (index != null) {
                _products[index] = p;
              } else {
                _products.add(p);
              }
            });
          },
        ),
      ),
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text(
          'Voulez-vous vraiment supprimer "${_products[index].name}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _products.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FORMULAIRE PRODUIT
// ============================================================
class AdminProductFormPage extends StatefulWidget {
  final ProductModel? existing;
  final Function(ProductModel) onSave;

  const AdminProductFormPage({
    super.key,
    this.existing,
    required this.onSave,
  });

  @override
  State<AdminProductFormPage> createState() => _AdminProductFormPageState();
}

class _AdminProductFormPageState extends State<AdminProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _normalPriceCtrl;
  late TextEditingController _promoPriceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _storeNameCtrl;
  late TextEditingController _weightCtrl;
  String _categoryId = '1';
  int _expiryDays = 7;

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
    _storeNameCtrl =
        TextEditingController(text: e?.storeName ?? '');
    _weightCtrl = TextEditingController(text: e?.weightKg.toString() ?? '1.0');
    _categoryId = e?.categoryId ?? '1';
    if (e != null) {
      _expiryDays = e.daysUntilExpiry > 0 ? e.daysUntilExpiry : 1;
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
            _field(_nameCtrl, 'Nom du produit *', Icons.shopping_bag),
            const SizedBox(height: 12),
            _field(_descCtrl, 'Description', Icons.description, maxLines: 3),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(_normalPriceCtrl, 'Prix normal (F) *',
                      Icons.attach_money,
                      keyboard: TextInputType.number),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(_promoPriceCtrl, 'Prix promo (F) *',
                      Icons.local_offer,
                      keyboard: TextInputType.number),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(_stockCtrl, 'Stock *', Icons.inventory,
                      keyboard: TextInputType.number),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(_weightCtrl, 'Poids (kg) *', Icons.scale,
                      keyboard: TextInputType.number),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field(_storeNameCtrl, 'Magasin *', Icons.store),
            const SizedBox(height: 12),

            // Catégorie
            DropdownButtonFormField<String>(
              value: _categoryId,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(value: '1', child: Text('🥛 Laitier')),
                DropdownMenuItem(value: '2', child: Text('🥩 Viande')),
                DropdownMenuItem(value: '3', child: Text('🍞 Boulangerie')),
                DropdownMenuItem(value: '4', child: Text('🥤 Boissons')),
                DropdownMenuItem(value: '5', child: Text('🧴 Hygiène')),
              ],
              onChanged: (v) => setState(() => _categoryId = v ?? '1'),
            ),
            const SizedBox(height: 12),

            // Jours avant expiration
            DropdownButtonFormField<int>(
              value: _expiryDays,
              decoration: const InputDecoration(
                labelText: 'Expire dans',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
              ),
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

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check, color: Colors.white),
                label: Text(
                  isEdit ? 'Enregistrer les modifications' : 'Créer le produit',
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
            const SizedBox(height: 24),
          ],
        ),
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
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      validator: (v) {
        if (label.contains('*') && (v == null || v.trim().isEmpty)) {
          return 'Champ obligatoire';
        }
        return null;
      },
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final product = ProductModel(
      id: widget.existing?.id ??
          'p${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      imageUrl: '',
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

    widget.onSave(product);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.existing != null
              ? 'Produit modifié ✅'
              : 'Produit ajouté ✅',
        ),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context);
  }
}
DART

# ============================================================
# PAGE: ADMIN CATEGORIES
# ============================================================
cat > lib/presentation/pages/admin/admin_categories_page.dart << 'DART'
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AdminCategoriesPage extends StatelessWidget {
  const AdminCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cats = [
      {'emoji': '🥛', 'name': 'Laitier', 'count': 12},
      {'emoji': '🥩', 'name': 'Viande', 'count': 8},
      {'emoji': '🍞', 'name': 'Boulangerie', 'count': 5},
      {'emoji': '🥤', 'name': 'Boissons', 'count': 14},
      {'emoji': '🧴', 'name': 'Hygiène', 'count': 6},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Admin • Catégories')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cats.length,
        itemBuilder: (context, i) {
          final c = cats[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(c['emoji'] as String,
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c['name'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${c['count']} produits',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {},
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouvelle', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
DART

# ============================================================
# PAGE: ADMIN STORES
# ============================================================
cat > lib/presentation/pages/admin/admin_stores_page.dart << 'DART'
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AdminStoresPage extends StatelessWidget {
  const AdminStoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stores = [
      {'name': 'Carrefour Cocody', 'products': 24, 'zone': 'Cocody'},
      {'name': 'Prosuma Plateau', 'products': 18, 'zone': 'Plateau'},
      {'name': 'Sococié Marcory', 'products': 12, 'zone': 'Marcory'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Admin • Magasins')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stores.length,
        itemBuilder: (context, i) {
          final s = stores[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.store, color: Colors.teal),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['name'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${s['zone']} • ${s['products']} produits',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () {},
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouveau', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
DART

# ============================================================
# PAGE: ADMIN USERS
# ============================================================
cat > lib/presentation/pages/admin/admin_users_page.dart << 'DART'
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final users = [
      {'name': 'Kouassi Yao', 'phone': '+225 07 00 00 00 00', 'orders': 5},
      {'name': 'Aya Koffi', 'phone': '+225 05 11 22 33 44', 'orders': 2},
      {'name': 'Moussa Traoré', 'phone': '+225 01 99 88 77 66', 'orders': 8},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Admin • Utilisateurs')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, i) {
          final u = users[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.purple.withOpacity(0.15),
                  child: Text(
                    (u['name'] as String)[0],
                    style: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u['name'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${u['phone']} • ${u['orders']} commandes',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.visibility,
                      color: AppColors.primary),
                  onPressed: () {},
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
DART

# ============================================================
# PAGE: ADMIN NOTIFICATIONS
# ============================================================
cat > lib/presentation/pages/admin/admin_notifications_page.dart << 'DART'
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() =>
      _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _target = 'all';

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
                    'Envoyez une notification push à tous vos clients',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Titre *',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              hintText: 'Ex: 🔥 Nouveau deal à Cocody',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Message *',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
          const SizedBox(height: 16),
          const Text(
            'Cible',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _target,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('📢 Tous les clients')),
              DropdownMenuItem(value: 'abidjan', child: Text('📍 Abidjan')),
              DropdownMenuItem(value: 'cocody', child: Text('📍 Cocody')),
              DropdownMenuItem(value: 'plateau', child: Text('📍 Plateau')),
            ],
            onChanged: (v) => setState(() => _target = v ?? 'all'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _send,
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text(
                'Envoyer la notification',
                style: TextStyle(
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

  void _send() {
    if (_titleCtrl.text.isEmpty || _bodyCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remplissez tous les champs')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Notification envoyée à tous les clients'),
        backgroundColor: AppColors.success,
      ),
    );

    _titleCtrl.clear();
    _bodyCtrl.clear();
  }
}
DART

# ============================================================
# APP ROUTER (avec routes admin)
# ============================================================
cat > lib/routes/app_router.dart << 'DART'
import 'package:go_router/go_router.dart';
import '../presentation/pages/splash/splash_page.dart';
import '../presentation/pages/home/home_page.dart';
import '../presentation/pages/cart/cart_page.dart';
import '../presentation/pages/checkout/checkout_page.dart';
import '../presentation/pages/payment/payment_methods_page.dart';
import '../presentation/pages/payment/mobile_money_page.dart';
import '../presentation/pages/payment/payment_success_page.dart';
import '../presentation/pages/auth/login_page.dart';
import '../presentation/pages/auth/register_page.dart';
import '../presentation/pages/auth/otp_page.dart';
import '../presentation/pages/profile/profile_page.dart';
import '../presentation/pages/orders/orders_page.dart';
import '../presentation/pages/orders/order_tracking_page.dart';
import '../presentation/pages/products/search_page.dart';
import '../presentation/pages/products/product_details_page.dart';
import '../presentation/pages/notifications/notifications_page.dart';
import '../presentation/pages/admin/admin_dashboard_page.dart';
import '../presentation/pages/admin/admin_orders_page.dart';
import '../presentation/pages/admin/admin_products_page.dart';
import '../presentation/pages/admin/admin_categories_page.dart';
import '../presentation/pages/admin/admin_stores_page.dart';
import '../presentation/pages/admin/admin_users_page.dart';
import '../presentation/pages/admin/admin_notifications_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashPage()),
    GoRoute(path: '/home', builder: (_, __) => const HomePage()),
    GoRoute(path: '/cart', builder: (_, __) => const CartPage()),
    GoRoute(path: '/checkout', builder: (_, __) => const CheckoutPage()),
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
    GoRoute(
      path: '/otp',
      builder: (_, state) => OtpPage(phone: state.extra as String? ?? ''),
    ),
    GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
    GoRoute(path: '/search', builder: (_, __) => const SearchPage()),
    GoRoute(
      path: '/notifications',
      builder: (_, __) => const NotificationsPage(),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (_, state) => ProductDetailsPage(
        productId: state.pathParameters['id'] ?? '1',
      ),
    ),
    GoRoute(
      path: '/orders',
      builder: (_, __) => const OrdersPage(),
      routes: [
        GoRoute(
          path: 'tracking',
          builder: (_, state) {
            final queryId = state.uri.queryParameters['id'];
            final extraId = state.extra as String?;
            return OrderTrackingPage(
              orderId: queryId ?? extraId ?? '#FD-001',
            );
          },
        ),
      ],
    ),
    // === ADMIN ===
    GoRoute(
      path: '/admin',
      builder: (_, __) => const AdminDashboardPage(),
      routes: [
        GoRoute(path: 'orders', builder: (_, __) => const AdminOrdersPage()),
        GoRoute(
            path: 'products',
            builder: (_, __) => const AdminProductsPage()),
        GoRoute(
            path: 'categories',
            builder: (_, __) => const AdminCategoriesPage()),
        GoRoute(
            path: 'stores', builder: (_, __) => const AdminStoresPage()),
        GoRoute(path: 'users', builder: (_, __) => const AdminUsersPage()),
        GoRoute(
            path: 'notifications',
            builder: (_, __) => const AdminNotificationsPage()),
      ],
    ),
    GoRoute(
      path: '/payment',
      builder: (_, __) => const PaymentMethodsPage(),
      routes: [
        GoRoute(path: 'mobile', builder: (_, __) => const MobileMoneyPage()),
        GoRoute(
          path: 'success',
          builder: (_, state) {
            final orderId = state.uri.queryParameters['orderId'];
            return PaymentSuccessPage(orderId: orderId);
          },
        ),
      ],
    ),
  ],
);
DART

echo "✅ Back-office admin créé !"
