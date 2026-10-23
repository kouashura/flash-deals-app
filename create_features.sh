#!/bin/bash
echo "🔍 Création recherche + notifications + PDF..."

# ============================================================
# PDF SERVICE
# ============================================================
cat > lib/core/services/pdf_service.dart << 'DART'
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  Future<void> generateInvoice({
    required String orderId,
    required String customerName,
    required String phone,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required int deliveryFee,
    required double total,
    required DateTime date,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FLASH DEALS',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.orange,
                        ),
                      ),
                      pw.Text('Abidjan, Côte d\'Ivoire'),
                      pw.Text('contact@flashdeals.ci'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'FACTURE',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(orderId),
                      pw.Text(
                        '${date.day}/${date.month}/${date.year}',
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),

              // CLIENT
              pw.Text(
                'Client',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(customerName),
              pw.Text(phone),
              pw.SizedBox(height: 20),

              // TABLE
              pw.TableHelper.fromTextArray(
                headers: ['Produit', 'Qté', 'Prix', 'Total'],
                data: items.map((item) {
                  return [
                    item['name'],
                    item['quantity'].toString(),
                    '${item['price']} F',
                    '${item['total']} F',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.orange,
                ),
              ),

              pw.SizedBox(height: 20),

              // TOTAUX
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.SizedBox(
                  width: 200,
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Sous-total'),
                          pw.Text('$subtotal F'),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Livraison'),
                          pw.Text('$deliveryFee F'),
                        ],
                      ),
                      pw.Divider(),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'TOTAL',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            '$total F',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              pw.SizedBox(height: 40),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Merci pour votre commande !',
                  style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => doc.save(),
      name: 'facture_$orderId.pdf',
    );
  }
}
DART

# ============================================================
# NOTIFICATION BLOC — Event
# ============================================================
cat > lib/presentation/blocs/notification/notification_event.dart << 'DART'
import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {
  const LoadNotifications();
}

class MarkAsRead extends NotificationEvent {
  final String id;
  const MarkAsRead(this.id);

  @override
  List<Object?> get props => [id];
}

class MarkAllAsRead extends NotificationEvent {
  const MarkAllAsRead();
}
DART

# ============================================================
# NOTIFICATION BLOC — State
# ============================================================
cat > lib/presentation/blocs/notification/notification_state.dart << 'DART'
import 'package:equatable/equatable.dart';
import '../../../domain/entities/notification.dart';

class NotificationState extends Equatable {
  final List<AppNotification> notifications;

  const NotificationState({this.notifications = const []});

  int get unreadCount =>
      notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({List<AppNotification>? notifications}) =>
      NotificationState(notifications: notifications ?? this.notifications);

  @override
  List<Object?> get props => [notifications];
}
DART

# ============================================================
# NOTIFICATION BLOC
# ============================================================
cat > lib/presentation/blocs/notification/notification_bloc.dart << 'DART'
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/notification.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc
    extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc() : super(const NotificationState()) {
    on<LoadNotifications>(_onLoad);
    on<MarkAsRead>(_onRead);
    on<MarkAllAsRead>(_onAllRead);
  }

  void _onLoad(LoadNotifications event, Emitter<NotificationState> emit) {
    // Données démo
    final demo = [
      AppNotification(
        id: '1',
        title: '🔥 Nouveau deal à Cocody',
        body: 'Lait Candia à -50% chez Carrefour Cocody',
        type: 'deal',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      AppNotification(
        id: '2',
        title: '📦 Commande en route',
        body: 'Votre commande #FD-002 est en cours de livraison',
        type: 'order',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: '3',
        title: '🎁 100 points offerts',
        body: 'Félicitations ! Vous avez gagné 100 points fidélité',
        type: 'promo',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ];
    emit(state.copyWith(notifications: demo));
  }

  void _onRead(MarkAsRead event, Emitter<NotificationState> emit) {
    final updated = state.notifications.map((n) {
      if (n.id == event.id) {
        return AppNotification(
          id: n.id,
          title: n.title,
          body: n.body,
          type: n.type,
          createdAt: n.createdAt,
          isRead: true,
        );
      }
      return n;
    }).toList();
    emit(state.copyWith(notifications: updated));
  }

  void _onAllRead(MarkAllAsRead event, Emitter<NotificationState> emit) {
    final updated = state.notifications.map((n) {
      return AppNotification(
        id: n.id,
        title: n.title,
        body: n.body,
        type: n.type,
        createdAt: n.createdAt,
        isRead: true,
      );
    }).toList();
    emit(state.copyWith(notifications: updated));
  }
}
DART

# ============================================================
# PAGE: SEARCH
# ============================================================
cat > lib/presentation/pages/products/search_page.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../core/utils/formatters.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  List<ProductModel> get _allProducts => [
        ProductModel(
          id: '1', name: 'Lait Candia 1L', description: '',
          imageUrl: '', categoryId: '1', storeId: 's1',
          storeName: 'Carrefour Cocody',
          normalPrice: 1200, promoPrice: 600, stock: 3,
          expiryDate: DateTime.now().add(const Duration(days: 3)),
          isFlashDeal: true,
        ),
        ProductModel(
          id: '2', name: 'Yaourt Activia x4', description: '',
          imageUrl: '', categoryId: '1', storeId: 's2',
          storeName: 'Prosuma Plateau',
          normalPrice: 2500, promoPrice: 1500, stock: 8,
          expiryDate: DateTime.now().add(const Duration(days: 5)),
          isFlashDeal: true,
        ),
        ProductModel(
          id: '3', name: 'Steak haché 500g', description: '',
          imageUrl: '', categoryId: '2', storeId: 's1',
          storeName: 'Carrefour Cocody',
          normalPrice: 3500, promoPrice: 2000, stock: 2,
          expiryDate: DateTime.now().add(const Duration(days: 1)),
          isFlashDeal: true,
        ),
        ProductModel(
          id: '4', name: 'Pain complet', description: '',
          imageUrl: '', categoryId: '3', storeId: 's3',
          storeName: 'Sococié Marcory',
          normalPrice: 800, promoPrice: 400, stock: 15,
          expiryDate: DateTime.now().add(const Duration(days: 2)),
          isFlashDeal: true,
        ),
        ProductModel(
          id: '5', name: 'Jus d\'orange 1L', description: '',
          imageUrl: '', categoryId: '4', storeId: 's2',
          storeName: 'Prosuma Plateau',
          normalPrice: 1800, promoPrice: 1000, stock: 10,
          expiryDate: DateTime.now().add(const Duration(days: 6)),
          isFlashDeal: true,
        ),
      ];

  List<ProductModel> get _filtered {
    if (_query.isEmpty) return [];
    return _allProducts
        .where((p) =>
            p.name.toLowerCase().contains(_query.toLowerCase()) ||
            p.storeName.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(
            hintText: 'Rechercher un produit...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _query.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 80, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Recherchez un produit ou un magasin',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : results.isEmpty
              ? const Center(child: Text('Aucun résultat'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final p = results[i];
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => context.push('/product/${p.id}'),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.image,
                                    color: Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    Text(p.storeName,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text(Formatters.price(p.promoPrice),
                                        style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
# PAGE: NOTIFICATIONS
# ============================================================
cat > lib/presentation/pages/notifications/notifications_page.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/notification/notification_event.dart';
import '../../blocs/notification/notification_state.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => context
                .read<NotificationBloc>()
                .add(const MarkAllAsRead()),
            child: const Text('Tout lire',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state.notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Aucune notification'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.notifications.length,
            itemBuilder: (context, i) {
              final n = state.notifications[i];
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context
                      .read<NotificationBloc>()
                      .add(MarkAsRead(n.id)),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: n.isRead
                          ? Colors.white
                          : AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: n.isRead
                          ? null
                          : Border.all(
                              color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            n.type == 'deal'
                                ? Icons.local_offer
                                : n.type == 'order'
                                    ? Icons.local_shipping
                                    : Icons.card_giftcard,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                style: TextStyle(
                                  fontWeight: n.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.body,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${n.createdAt.hour}h${n.createdAt.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
DART

# ============================================================
# PAGE: PRODUCT DETAILS (simple)
# ============================================================
cat > lib/presentation/pages/products/product_details_page.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product_model.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';

class ProductDetailsPage extends StatelessWidget {
  final String productId;
  const ProductDetailsPage({super.key, required this.productId});

  ProductModel get _product => ProductModel(
        id: productId,
        name: 'Produit #$productId',
        description: 'Description du produit. Ce produit est en promotion '
            'car sa date de péremption est proche.',
        imageUrl: '',
        categoryId: '1',
        storeId: 's1',
        storeName: 'Carrefour Cocody',
        normalPrice: 2000,
        promoPrice: 1000,
        stock: 5,
        expiryDate: DateTime.now().add(const Duration(days: 3)),
        isFlashDeal: true,
        rating: 4.5,
        reviewCount: 12,
      );

  @override
  Widget build(BuildContext context) {
    final p = _product;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(p.name)),
      body: ListView(
        children: [
          Container(
            height: 250,
            color: Colors.grey.shade200,
            child: const Center(
              child: Icon(Icons.image, size: 80, color: Colors.grey),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text(p.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(p.storeName,
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(Formatters.price(p.promoPrice),
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                    const SizedBox(width: 10),
                    Text(Formatters.price(p.normalPrice),
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough)),
                  ],
                ),
                const SizedBox(height: 12),
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
                const Text('Description',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(p.description,
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<CartBloc>().add(AddToCart(p));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('${p.name} ajouté au panier')),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart,
                        color: Colors.white),
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
DART

# ============================================================
# ROUTER (mis à jour)
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
          builder: (_, state) => OrderTrackingPage(
            orderId: state.extra as String? ?? '#FD-001',
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/payment',
      builder: (_, __) => const PaymentMethodsPage(),
      routes: [
        GoRoute(path: 'mobile', builder: (_, __) => const MobileMoneyPage()),
        GoRoute(
            path: 'success',
            builder: (_, __) => const PaymentSuccessPage()),
      ],
    ),
  ],
);
DART

# ============================================================
# APP (ajout NotificationBloc)
# ============================================================
cat > lib/app.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/di/injection_container.dart';
import 'presentation/blocs/cart/cart_bloc.dart';
import 'presentation/blocs/cart/cart_event.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/notification/notification_bloc.dart';
import 'presentation/blocs/notification/notification_event.dart';

class FlashDealsApp extends StatelessWidget {
  const FlashDealsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CartBloc(sl())..add(const LoadCart()),
        ),
        BlocProvider(
          create: (_) => AuthBloc(sl())..add(const CheckAuthStatus()),
        ),
        BlocProvider(
          create: (_) => NotificationBloc()
            ..add(const LoadNotifications()),
        ),
      ],
      child: MaterialApp.router(
        title: 'Flash Deals',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
      ),
    );
  }
}
DART

echo "✅ Recherche + notifications + PDF créés !"
