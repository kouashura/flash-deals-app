import 'package:go_router/go_router.dart';
import '../presentation/pages/splash/splash_page.dart';
import '../presentation/pages/home/home_page.dart';
import '../presentation/pages/cart/cart_page.dart';
import '../presentation/pages/checkout/checkout_page.dart';
import '../presentation/pages/checkout/map_picker_page.dart';
import '../presentation/pages/payment/payment_methods_page.dart';
import '../presentation/pages/payment/paiement_pro_page.dart';
import '../presentation/pages/payment/payment_success_page.dart';
import '../presentation/pages/auth/login_page.dart';
import '../presentation/pages/auth/register_page.dart';
import '../presentation/pages/profile/profile_page.dart';
import '../presentation/pages/courier/courier_login_page.dart';
import '../presentation/pages/courier/courier_register_page.dart';
import '../presentation/pages/courier/courier_dashboard_page.dart';
import '../presentation/pages/profile/addresses_page.dart';
import '../presentation/pages/favorites/favorites_page.dart';
import '../presentation/pages/profile/payments_page.dart';
import '../presentation/pages/profile/settings_page.dart';
import '../presentation/pages/profile/help_page.dart';
import '../presentation/pages/profile/terms_page.dart';
import '../presentation/pages/profile/privacy_page.dart';
import '../presentation/pages/orders/orders_page.dart';
import '../presentation/pages/reviews/write_review_page.dart';
import '../presentation/pages/orders/order_tracking_page.dart';
import '../presentation/pages/products/search_page.dart';
import '../presentation/pages/products/product_details_page.dart';
import '../presentation/pages/notifications/notifications_page.dart';
import '../presentation/pages/admin/admin_dashboard_page.dart';
import '../presentation/pages/admin/admin_orders_page.dart';
import '../presentation/pages/admin/admin_deliveries_page.dart';
import '../presentation/pages/admin/admin_products_page.dart';
import '../presentation/pages/admin/admin_categories_page.dart';
import '../presentation/pages/admin/admin_stores_page.dart';
import '../presentation/pages/admin/admin_users_page.dart';
import '../presentation/pages/admin/admin_notifications_page.dart';
import '../presentation/pages/admin/seed_page.dart';
import '../presentation/pages/admin/admin_flash_deals_page.dart';
import '../presentation/pages/admin/test_upload_page.dart';
import '../presentation/screens/wallet/wallet_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/wallet',
      builder: (context, state) => const WalletScreen(),
    ),
    GoRoute(path: '/', builder: (_, __) => const SplashPage()),
    GoRoute(path: '/home', builder: (_, __) => const HomePage()),
    GoRoute(path: '/cart', builder: (_, __) => const CartPage()),
    GoRoute(path: '/checkout', builder: (_, __) => const CheckoutPage()),
    GoRoute(path: '/map-picker', builder: (_, __) => const MapPickerPage()),
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
    GoRoute(
      path: '/profile',
      builder: (_, __) => const ProfilePage(),
      routes: [
        GoRoute(
            path: 'addresses',
            builder: (_, __) => const AddressesPage()),
        GoRoute(
            path: 'payments', builder: (_, __) => const PaymentsPage()),
        GoRoute(
            path: 'settings', builder: (_, __) => const SettingsPage()),
        GoRoute(path: 'help', builder: (_, __) => const HelpPage()),
        GoRoute(path: 'terms', builder: (_, __) => const TermsPage()),
        GoRoute(path: 'privacy', builder: (_, __) => const PrivacyPage()),
      ],
    ),
    GoRoute(path: '/favorites', builder: (_, __) => const FavoritesPage()),
    GoRoute(path: '/search', builder: (_, __) => const SearchPage()),
    GoRoute(path: '/test-upload', builder: (_, __) => const TestUploadPage()),
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
    // ═══ AVIS CLIENTS ═══
    GoRoute(
      path: '/review/write',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return WriteReviewPage(
          productId: extra['productId'] as String? ?? '',
          orderId: extra['orderId'] as String? ?? '',
          productName: extra['productName'] as String? ?? 'Produit',
          productImage: extra['productImage'] as String? ?? '',
        );
      },
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
    GoRoute(
      path: '/admin',
      builder: (_, __) => const AdminDashboardPage(),
      routes: [
        GoRoute(path: 'orders', builder: (_, __) => const AdminOrdersPage()),
        GoRoute(path: 'deliveries', builder: (_, __) => const AdminDeliveriesPage()),
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
        GoRoute(path: 'seed', builder: (_, __) => const SeedPage()),
        GoRoute(path: 'flash-deals', builder: (_, __) => const AdminFlashDealsPage()),
      ],
    ),
    // ═══ ESPACE LIVREUR ═══
    GoRoute(
      path: '/courier/login',
      builder: (_, __) => const CourierLoginPage(),
    ),
    GoRoute(
      path: '/courier/register',
      builder: (_, __) => const CourierRegisterPage(),
    ),
    GoRoute(
      path: '/courier/dashboard',
      builder: (_, __) => const CourierDashboardPage(),
    ),
    GoRoute(
      path: '/payment',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final total = (extra['total'] as num?)?.toDouble() ?? 0.0;
        return PaymentMethodsPage(total: total);
      },
      routes: [
        GoRoute(
          path: 'pro',
          builder: (_, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return PaiementProPage(
              channel: extra['channel'] as String? ?? 'ALL',
              channelLabel: extra['channelLabel'] as String? ?? 'Paiement Pro',
              phone: extra['phone'] as String?,
              address: extra['address'] as String?,
              deliveryFee: extra['deliveryFee'] as int?,
              zone: extra['zone'] as String?,
              timeSlot: extra['timeSlot'] as String?,
            );
          },
        ),
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
