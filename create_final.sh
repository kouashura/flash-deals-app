#!/bin/bash
echo "🎨 Finalisation du projet..."

# ============================================================
# CATEGORY CHIPS (cliquable + callback)
# ============================================================
cat > lib/presentation/pages/home/widgets/category_chips.dart << 'DART'
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CategoryChips extends StatefulWidget {
  final ValueChanged<String>? onSelected;

  const CategoryChips({super.key, this.onSelected});

  @override
  State<CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<CategoryChips> {
  int _selected = 0;

  final _categories = const [
    {'id': 'all', 'icon': '🛒', 'label': 'Tout'},
    {'id': '1', 'icon': '🥛', 'label': 'Laitier'},
    {'id': '2', 'icon': '🥩', 'label': 'Viande'},
    {'id': '3', 'icon': '🍞', 'label': 'Boulangerie'},
    {'id': '4', 'icon': '🥤', 'label': 'Boissons'},
    {'id': '5', 'icon': '🧴', 'label': 'Hygiène'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final selected = i == _selected;
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() => _selected = i);
                widget.onSelected?.call(cat['id']!);
              },
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cat['icon']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      color: selected
                          ? AppColors.primary
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
DART

# ============================================================
# HOME PAGE (avec filtre catégorie)
# ============================================================
cat > lib/presentation/pages/home/home_page.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_state.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/notification/notification_state.dart';
import 'widgets/category_chips.dart';
import 'widgets/delivery_banner.dart';
import 'widgets/flash_deals_banner.dart';
import 'widgets/product_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedCategory = 'all';

  final List<ProductModel> _allProducts = [
    ProductModel(
      id: '1', name: 'Lait Candia 1L', description: '',
      imageUrl: '', categoryId: '1', storeId: 's1',
      storeName: 'Carrefour Cocody',
      normalPrice: 1200, promoPrice: 600, stock: 3,
      expiryDate: DateTime.now().add(const Duration(days: 3)),
      isFlashDeal: true, rating: 4.5, reviewCount: 12,
    ),
    ProductModel(
      id: '2', name: 'Yaourt Activia x4', description: '',
      imageUrl: '', categoryId: '1', storeId: 's2',
      storeName: 'Prosuma Plateau',
      normalPrice: 2500, promoPrice: 1500, stock: 8,
      expiryDate: DateTime.now().add(const Duration(days: 5)),
      isFlashDeal: true, rating: 4.2, reviewCount: 8,
    ),
    ProductModel(
      id: '3', name: 'Steak haché 500g', description: '',
      imageUrl: '', categoryId: '2', storeId: 's1',
      storeName: 'Carrefour Cocody',
      normalPrice: 3500, promoPrice: 2000, stock: 2,
      expiryDate: DateTime.now().add(const Duration(days: 1)),
      isFlashDeal: true, rating: 4.8, reviewCount: 25,
    ),
    ProductModel(
      id: '4', name: 'Pain complet', description: '',
      imageUrl: '', categoryId: '3', storeId: 's3',
      storeName: 'Sococié Marcory',
      normalPrice: 800, promoPrice: 400, stock: 15,
      expiryDate: DateTime.now().add(const Duration(days: 2)),
      isFlashDeal: true, rating: 4.0, reviewCount: 5,
    ),
    ProductModel(
      id: '5', name: 'Jus d\'orange 1L', description: '',
      imageUrl: '', categoryId: '4', storeId: 's2',
      storeName: 'Prosuma Plateau',
      normalPrice: 1800, promoPrice: 1000, stock: 10,
      expiryDate: DateTime.now().add(const Duration(days: 6)),
      isFlashDeal: true, rating: 4.3, reviewCount: 18,
    ),
    ProductModel(
      id: '6', name: 'Fromage râpé 200g', description: '',
      imageUrl: '', categoryId: '1', storeId: 's1',
      storeName: 'Carrefour Cocody',
      normalPrice: 2200, promoPrice: 1200, stock: 4,
      expiryDate: DateTime.now().add(const Duration(days: 4)),
      isFlashDeal: true, rating: 4.6, reviewCount: 10,
    ),
  ];

  List<ProductModel> get _filteredProducts {
    if (_selectedCategory == 'all') return _allProducts;
    return _allProducts
        .where((p) => p.categoryId == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Flash Deals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              final unread = state.unreadCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.push('/notifications'),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => context.push('/cart'),
                  ),
                  if (state.cart.totalItems > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${state.cart.totalItems}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            await Future.delayed(const Duration(seconds: 1)),
        child: ListView(
          children: [
            const DeliveryBanner(),
            const FlashDealsBanner(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Catégories',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            CategoryChips(
              onSelected: (catId) {
                setState(() => _selectedCategory = catId);
              },
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🔥 Deals du moment',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    '${products.length} produit${products.length > 1 ? "s" : ""}',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (products.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text('Aucun produit dans cette catégorie'),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemCount: products.length,
                itemBuilder: (context, i) {
                  return ProductCard(
                    product: products[i],
                    onTap: () =>
                        context.push('/product/${products[i].id}'),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
DART

# ============================================================
# ORDER TRACKING (avec bouton PDF)
# ============================================================
cat > lib/presentation/pages/orders/order_tracking_page.dart << 'DART'
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/pdf_service.dart';

class OrderTrackingPage extends StatelessWidget {
  final String orderId;
  const OrderTrackingPage({super.key, required this.orderId});

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      await PdfService().generateInvoice(
        orderId: orderId,
        customerName: 'Kouassi Yao',
        phone: '+225 07 00 00 00 00',
        items: [
          {'name': 'Lait Candia 1L', 'quantity': 2, 'price': 600, 'total': 1200},
          {'name': 'Yaourt Activia x4', 'quantity': 1, 'price': 1500, 'total': 1500},
          {'name': 'Fromage râpé', 'quantity': 1, 'price': 1200, 'total': 1200},
        ],
        subtotal: 3900,
        deliveryFee: 1500,
        total: 5400,
        date: DateTime.now(),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur PDF : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      {
        'title': 'Commande confirmée',
        'subtitle': '27/09/2025 à 10:15',
        'icon': Icons.check_circle,
        'done': true,
      },
      {
        'title': 'En préparation',
        'subtitle': 'Au magasin Carrefour Cocody',
        'icon': Icons.inventory_2,
        'done': true,
      },
      {
        'title': 'En cours de livraison',
        'subtitle': 'Livreur en route vers Cocody',
        'icon': Icons.delivery_dining,
        'done': true,
      },
      {
        'title': 'Livré',
        'subtitle': 'En attente',
        'icon': Icons.home,
        'done': false,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Suivi $orderId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Télécharger la facture',
            onPressed: () => _downloadPdf(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Livraison en cours',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Arrivée estimée : aujourd\'hui entre 14h et 16h',
                    style: TextStyle(color: Colors.grey)),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 6),
                    Text('Cocody, Abidjan',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: List.generate(steps.length, (i) {
                final step = steps[i];
                final isLast = i == steps.length - 1;
                final done = step['done'] as bool;
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: done
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              step['icon'] as IconData,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: done
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step['title'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      done ? Colors.black : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                step['subtitle'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Yao (Livreur)',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('+225 07 XX XX XX XX',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone,
                      color: AppColors.success),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _downloadPdf(context),
              icon: const Icon(Icons.download, color: Colors.white),
              label: const Text(
                'Télécharger la facture PDF',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
DART

# ============================================================
# SPLASH PRO (avec logo et animation)
# ============================================================
cat > lib/presentation/pages/splash/splash_page.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Flash Deals',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ABIDJAN',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
DART

# ============================================================
# BOTTOM NAV BAR (navigation)
# ============================================================
cat > lib/presentation/widgets/navigation/main_scaffold.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_state.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/notification/notification_state.dart';
import '../../pages/home/home_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _index == 0
          ? const HomePage()
          : Center(
              child: Text(
                'Page ${_index + 1}',
                style: const TextStyle(fontSize: 20),
              ),
            ),
      bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          return BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, notifState) {
              return BottomNavigationBar(
                currentIndex: _index,
                onTap: (i) {
                  if (i == 1) {
                    context.push('/search');
                  } else if (i == 2) {
                    context.push('/notifications');
                  } else if (i == 3) {
                    context.push('/cart');
                  } else if (i == 4) {
                    context.push('/profile');
                  } else {
                    setState(() => _index = i);
                  }
                },
                type: BottomNavigationBarType.fixed,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: Colors.grey,
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Accueil',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.search),
                    label: 'Recherche',
                  ),
                  BottomNavigationBarItem(
                    icon: Stack(
                      children: [
                        const Icon(Icons.notifications),
                        if (notifState.unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${notifState.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    label: 'Alertes',
                  ),
                  BottomNavigationBarItem(
                    icon: Stack(
                      children: [
                        const Icon(Icons.shopping_cart),
                        if (cartState.cart.totalItems > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${cartState.cart.totalItems}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    label: 'Panier',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profil',
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
DART

echo "✅ Finalisation terminée !"
