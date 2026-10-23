#!/bin/bash
echo "📝 Création des fichiers Dart..."

# === CORE / CONFIG ===
cat > lib/core/config/app_config.dart << 'DART'
class AppConfig {
  static const String appName = 'Flash Deals Abidjan';
  static const String appVersion = '1.0.0';
}
DART

cat > lib/core/config/env.dart << 'DART'
class Env {
  static const String apiBaseUrl = 'https://api.flashdeals.ci/v1';
}
DART

cat > lib/core/config/routes.dart << 'DART'
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String delivery = '/delivery';
  static const String payment = '/payment';
  static const String orders = '/orders';
  static const String profile = '/profile';
}
DART

# === CORE / CONSTANTS ===
cat > lib/core/constants/app_colors.dart << 'DART'
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF6B00);
  static const Color secondary = Color(0xFF1E88E5);
  static const Color background = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color success = Color(0xFF43A047);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFB8C00);
}
DART

cat > lib/core/constants/app_strings.dart << 'DART'
class AppStrings {
  static const String appName = 'Flash Deals';
  static const String deliveryFeeLabel = 'Frais de livraison';
  static const String deliveryFeeAbidjan = '1 500 FCFA';
  static const String checkout = 'Passer la commande';
  static const String payNow = 'Payer maintenant';
}
DART

cat > lib/core/constants/app_sizes.dart << 'DART'
class AppSizes {
  static const double padding = 16.0;
  static const double radius = 12.0;
  static const double buttonHeight = 52.0;
}
DART

cat > lib/core/constants/app_assets.dart << 'DART'
class AppAssets {
  static const String logo = 'assets/images/logo/logo.png';
  static const String placeholder = 'assets/images/placeholders/product.png';
}
DART

cat > lib/core/constants/api_endpoints.dart << 'DART'
class ApiEndpoints {
  static const String baseUrl = 'https://api.flashdeals.ci/v1';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String products = '/products';
  static const String flashDeals = '/products/flash-deals';
  static const String orders = '/orders';
  static const String delivery = '/delivery';
  static const String payments = '/payments';
}
DART

cat > lib/core/constants/delivery_constants.dart << 'DART'
class DeliveryConstants {
  /// Frais de livraison fixes pour Abidjan (FCFA)
  static const int abidjanDeliveryFee = 1500;

  /// Devise
  static const String currency = 'FCFA';

  /// Zones couvertes (à étendre)
  static const List<String> abidjanZones = [
    'Cocody',
    'Plateau',
    'Yopougon',
    'Adjamé',
    'Abobo',
    'Treichville',
    'Marcory',
    'Koumassi',
    'Port-Bouët',
    'Bingerville',
    'Riviera',
    'Angré',
  ];

  /// Créneaux horaires
  static const List<String> timeSlots = [
    '08h - 10h',
    '10h - 12h',
    '12h - 14h',
    '14h - 16h',
    '16h - 18h',
    '18h - 20h',
  ];
}
DART

cat > lib/core/constants/payment_constants.dart << 'DART'
class PaymentConstants {
  static const String orangeMoney = 'Orange Money';
  static const String mtnMomo = 'MTN Mobile Money';
  static const String moovMoney = 'Moov Money';
  static const String wave = 'Wave';
  static const String visaMastercard = 'Visa / Mastercard';
  static const String internalWallet = 'Wallet Flash Deals';
}
DART

# === CORE / UTILS ===
cat > lib/core/utils/formatters.dart << 'DART'
import 'package:intl/intl.dart';

class Formatters {
  static String price(num amount) {
    final f = NumberFormat('#,###', 'fr_FR');
    return '${f.format(amount)} FCFA';
  }

  static String date(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  static String dateTime(DateTime d) => DateFormat('dd/MM/yyyy HH:mm').format(d);
}
DART

cat > lib/core/utils/validators.dart << 'DART'
class Validators {
  static String? email(String? v) {
    if (v == null || v.isEmpty) return 'Email requis';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Email invalide';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.isEmpty) return 'Téléphone requis';
    if (v.length < 8) return 'Téléphone invalide';
    return null;
  }

  static String? required(String? v, [String field = 'Champ']) {
    if (v == null || v.isEmpty) return '$field requis';
    return null;
  }
}
DART

# === CORE / SERVICES ===
cat > lib/core/services/delivery_service.dart << 'DART'
import '../constants/delivery_constants.dart';

class DeliveryService {
  /// Retourne les frais de livraison (fixe pour Abidjan)
  int calculateFee({required String zone}) {
    if (DeliveryConstants.abidjanZones.contains(zone)) {
      return DeliveryConstants.abidjanDeliveryFee;
    }
    throw Exception('Zone non couverte : $zone');
  }

  bool isZoneCovered(String zone) =>
      DeliveryConstants.abidjanZones.contains(zone);
}
DART

cat > lib/core/services/location_service.dart << 'DART'
// TODO: Implémenter avec geolocator
class LocationService {
  Future<void> getCurrentPosition() async {
    // À implémenter
  }
}
DART

cat > lib/core/services/payment_service.dart << 'DART'
// TODO: Intégrer CinetPay / Wave / Orange Money
class PaymentService {
  Future<void> initiatePayment({required int amount}) async {
    // À implémenter
  }
}
DART

# === DI ===
cat > lib/core/di/injection_container.dart << 'DART'
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // TODO: Enregistrer les dépendances
}
DART

# === ROUTES ===
cat > lib/routes/app_router.dart << 'DART'
import 'package:go_router/go_router.dart';
import '../presentation/pages/splash/splash_page.dart';
import '../presentation/pages/home/home_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashPage()),
    GoRoute(path: '/home', builder: (_, __) => const HomePage()),
  ],
);
DART

cat > lib/routes/route_names.dart << 'DART'
class RouteNames {
  static const String splash = 'splash';
  static const String home = 'home';
  static const String login = 'login';
  static const String cart = 'cart';
  static const String checkout = 'checkout';
}
DART

# === MAIN & APP ===
cat > lib/main.dart << 'DART'
import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  runApp(const FlashDealsApp());
}
DART

cat > lib/app.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'routes/app_router.dart';
import 'core/theme/app_theme.dart';

class FlashDealsApp extends StatelessWidget {
  const FlashDealsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flash Deals',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
DART

# === THEME ===
cat > lib/core/theme/app_theme.dart << 'DART'
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      );
}
DART

# === PAGES DE BASE ===
cat > lib/presentation/pages/splash/splash_page.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Flash Deals')),
    );
  }
}
DART

cat > lib/presentation/pages/home/home_page.dart << 'DART'
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flash Deals Abidjan')),
      body: const Center(child: Text('Accueil')),
    );
  }
}
DART

echo "✅ Fichiers Dart créés avec succès !"
