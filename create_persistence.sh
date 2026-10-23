#!/bin/bash
echo "💾 Création de la persistance + suivi livraison..."

# ============================================================
# STORAGE SERVICE (SharedPreferences)
# ============================================================
cat > lib/core/services/storage_service.dart << 'DART'
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _cartKey = 'cart_items';
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ============ CART ============
  Future<void> saveCart(List<Map<String, dynamic>> items) async {
    await _prefs.setString(_cartKey, jsonEncode(items));
  }

  List<Map<String, dynamic>> loadCart() {
    final raw = _prefs.getString(_cartKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> clearCart() async {
    await _prefs.remove(_cartKey);
  }

  // ============ USER ============
  Future<void> saveUser(Map<String, dynamic> user) async {
    await _prefs.setString(_userKey, jsonEncode(user));
  }

  Map<String, dynamic>? loadUser() {
    final raw = _prefs.getString(_userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clearUser() async {
    await _prefs.remove(_userKey);
  }

  // ============ TOKEN ============
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  String? loadToken() => _prefs.getString(_tokenKey);

  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
DART

# ============================================================
# CART BLOC (mise à jour avec persistance)
# ============================================================
cat > lib/presentation/blocs/cart/cart_bloc.dart << 'DART'
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/models/product_model.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/cart_item.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final StorageService _storage;

  CartBloc(this._storage) : super(const CartState()) {
    on<LoadCart>(_onLoad);
    on<AddToCart>(_onAdd);
    on<RemoveFromCart>(_onRemove);
    on<UpdateQuantity>(_onUpdate);
    on<ClearCart>(_onClear);
  }

  void _onLoad(LoadCart event, Emitter<CartState> emit) {
    final raw = _storage.loadCart();
    final items = raw.map((json) {
      return CartItemModel.fromJson(json);
    }).toList();
    emit(state.copyWith(cart: Cart(items: items)));
  }

  void _persist(List<CartItem> items) {
    final json = items.map((item) {
      return CartItemModel(
        product: item.product as ProductModel,
        quantity: item.quantity,
      ).toJson();
    }).toList();
    _storage.saveCart(json);
  }

  void _onAdd(AddToCart event, Emitter<CartState> emit) {
    final currentItems = List<CartItem>.from(state.cart.items);
    final index = currentItems.indexWhere(
      (item) => item.product.id == event.product.id,
    );

    if (index >= 0) {
      final existing = currentItems[index];
      currentItems[index] = existing.copyWith(
        quantity: existing.quantity + event.quantity,
      );
    } else {
      currentItems.add(CartItem(
        product: event.product,
        quantity: event.quantity,
      ));
    }

    _persist(currentItems);
    emit(state.copyWith(cart: Cart(items: currentItems)));
  }

  void _onRemove(RemoveFromCart event, Emitter<CartState> emit) {
    final currentItems = state.cart.items
        .where((item) => item.product.id != event.productId)
        .toList();
    _persist(currentItems);
    emit(state.copyWith(cart: Cart(items: currentItems)));
  }

  void _onUpdate(UpdateQuantity event, Emitter<CartState> emit) {
    final currentItems = state.cart.items
        .map((item) {
          if (item.product.id == event.productId) {
            return item.copyWith(quantity: event.quantity);
          }
          return item;
        })
        .where((item) => item.quantity > 0)
        .toList();

    _persist(currentItems);
    emit(state.copyWith(cart: Cart(items: currentItems)));
  }

  void _onClear(ClearCart event, Emitter<CartState> emit) {
    _storage.clearCart();
    emit(const CartState(cart: Cart()));
  }
}
DART

# ============================================================
# CART EVENT (ajout LoadCart)
# ============================================================
cat > lib/presentation/blocs/cart/cart_event.dart << 'DART'
import 'package:equatable/equatable.dart';
import '../../../domain/entities/product.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class LoadCart extends CartEvent {
  const LoadCart();
}

class AddToCart extends CartEvent {
  final Product product;
  final int quantity;

  const AddToCart(this.product, {this.quantity = 1});

  @override
  List<Object?> get props => [product, quantity];
}

class RemoveFromCart extends CartEvent {
  final String productId;

  const RemoveFromCart(this.productId);

  @override
  List<Object?> get props => [productId];
}

class UpdateQuantity extends CartEvent {
  final String productId;
  final int quantity;

  const UpdateQuantity(this.productId, this.quantity);

  @override
  List<Object?> get props => [productId, quantity];
}

class ClearCart extends CartEvent {
  const ClearCart();
}
DART

# ============================================================
# AUTH BLOC (mise à jour avec persistance)
# ============================================================
cat > lib/presentation/blocs/auth/auth_bloc.dart << 'DART'
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/models/user_model.dart';
import '../../../domain/entities/user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final StorageService _storage;

  AuthBloc(this._storage) : super(const AuthInitial()) {
    on<CheckAuthStatus>(_onCheck);
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<VerifyOtp>(_onVerifyOtp);
    on<LogoutRequested>(_onLogout);
  }

  void _onCheck(CheckAuthStatus event, Emitter<AuthState> emit) {
    final raw = _storage.loadUser();
    if (raw != null) {
      try {
        final user = UserModel.fromJson(raw);
        emit(AuthAuthenticated(user));
        return;
      } catch (_) {}
    }
    emit(const AuthUnauthenticated());
  }

  Future<void> _onLogin(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await Future.delayed(const Duration(seconds: 1));

    if (event.phone.length < 8) {
      emit(const AuthError('Numéro de téléphone invalide'));
      return;
    }

    emit(AuthOtpSent(event.phone));
  }

  Future<void> _onRegister(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await Future.delayed(const Duration(seconds: 1));

    if (event.fullName.isEmpty || event.phone.length < 8) {
      emit(const AuthError('Veuillez remplir tous les champs'));
      return;
    }

    emit(AuthOtpSent(event.phone));
  }

  Future<void> _onVerifyOtp(
    VerifyOtp event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await Future.delayed(const Duration(seconds: 1));

    if (event.code != '123456') {
      emit(const AuthError('Code incorrect (utilisez 123456)'));
      return;
    }

    const user = UserModel(
      id: 'u1',
      fullName: 'Kouassi Yao',
      phone: '+2250700000000',
      email: 'kouassi@flashdeals.ci',
      loyaltyPoints: 120,
    );

    await _storage.saveUser(user.toJson());
    await _storage.saveToken('demo_token_${DateTime.now().millisecondsSinceEpoch}');

    emit(AuthAuthenticated(user));
  }

  Future<void> _onLogout(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _storage.clearUser();
    await _storage.clearToken();
    emit(const AuthUnauthenticated());
  }
}
DART

# ============================================================
# PAGE: ORDER TRACKING (suivi livraison)
# ============================================================
cat > lib/presentation/pages/orders/order_tracking_page.dart << 'DART'
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class OrderTrackingPage extends StatelessWidget {
  final String orderId;
  const OrderTrackingPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    // Simulation : 4 étapes
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
      appBar: AppBar(title: Text('Suivi $orderId')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // === CARTE INFO ===
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Livraison en cours',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Arrivée estimée : aujourd\'hui entre 14h et 16h',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Icon(Icons.location_on, color: AppColors.primary, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Cocody, Abidjan',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // === TIMELINE ===
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
                                  color: done ? Colors.black : Colors.grey,
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

          // === LIVREUR ===
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
                      Text(
                        'Yao (Livreur)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '+225 07 XX XX XX XX',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone, color: AppColors.success),
                  onPressed: () {},
                ),
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
# ORDERS PAGE (mise à jour → clic vers tracking)
# ============================================================
cat > lib/presentation/pages/orders/orders_page.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = [
      {
        'id': '#FD-001',
        'date': '27/09/2025',
        'total': 4500,
        'status': 'Livrée',
        'color': AppColors.success,
      },
      {
        'id': '#FD-002',
        'date': '25/09/2025',
        'total': 2800,
        'status': 'En route',
        'color': AppColors.primary,
      },
      {
        'id': '#FD-003',
        'date': '20/09/2025',
        'total': 6000,
        'status': 'En préparation',
        'color': Colors.orange,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mes commandes')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, i) {
          final o = orders[i];
          return GestureDetector(
            onTap: () => context.push(
              '/orders/tracking',
              extra: o['id'],
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o['id'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          o['date'] as String,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${o['total']} FCFA',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (o['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      o['status'] as String,
                      style: TextStyle(
                        color: o['color'] as Color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
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
# ROUTER (ajout tracking)
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
# MAIN (init SharedPreferences)
# ============================================================
cat > lib/main.dart << 'DART'
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/storage_service.dart';
import 'core/di/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const FlashDealsApp());
}
DART

# ============================================================
# DI (injection avec StorageService)
# ============================================================
cat > lib/core/di/injection_container.dart << 'DART'
import 'package:get_it/get_it.dart';
import '../services/storage_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // StorageService
  final storage = StorageService();
  await storage.init();
  sl.registerSingleton<StorageService>(storage);
}
DART

# ============================================================
# APP (injection StorageService dans les blocs + LoadCart)
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

echo "✅ Persistance + suivi livraison créés !"
