#!/bin/bash
echo "🔐 Création de l'authentification + profil + persistance..."

# ============================================================
# AUTH BLOC — Event
# ============================================================
cat > lib/presentation/blocs/auth/auth_event.dart << 'DART'
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String phone;
  final String password;

  const LoginRequested({required this.phone, required this.password});

  @override
  List<Object?> get props => [phone, password];
}

class RegisterRequested extends AuthEvent {
  final String fullName;
  final String phone;
  final String email;
  final String password;

  const RegisterRequested({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [fullName, phone, email, password];
}

class VerifyOtp extends AuthEvent {
  final String code;

  const VerifyOtp(this.code);

  @override
  List<Object?> get props => [code];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}
DART

# ============================================================
# AUTH BLOC — State
# ============================================================
cat > lib/presentation/blocs/auth/auth_state.dart << 'DART'
import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthOtpSent extends AuthState {
  final String phone;
  const AuthOtpSent(this.phone);

  @override
  List<Object?> get props => [phone];
}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
DART

# ============================================================
# AUTH BLOC — Bloc (simulation locale)
# ============================================================
cat > lib/presentation/blocs/auth/auth_bloc.dart << 'DART'
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthInitial()) {
    on<CheckAuthStatus>(_onCheck);
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<VerifyOtp>(_onVerifyOtp);
    on<LogoutRequested>(_onLogout);
  }

  void _onCheck(CheckAuthStatus event, Emitter<AuthState> emit) {
    // Plus tard : vérifier SharedPreferences / token
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

    // Simulation : OTP envoyé
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

    // Simulation : utilisateur connecté
    emit(const AuthAuthenticated(
      User(
        id: 'u1',
        fullName: 'Kouassi Yao',
        phone: '+2250700000000',
        email: 'kouassi@flashdeals.ci',
        loyaltyPoints: 120,
      ),
    ));
  }

  void _onLogout(LogoutRequested event, Emitter<AuthState> emit) {
    emit(const AuthUnauthenticated());
  }
}
DART

# ============================================================
# PAGE: LOGIN
# ============================================================
cat > lib/presentation/pages/auth/login_page.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthOtpSent) {
            context.push('/otp', extra: state.phone);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Bienvenue 👋',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connectez-vous pour accéder aux deals',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    hintText: '+225 07 XX XX XX XX',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),
                if (loading)
                  const Center(child: CircularProgressIndicator())
                else
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(
                              LoginRequested(
                                phone: _phoneCtrl.text,
                                password: _passCtrl.text,
                              ),
                            );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Se connecter',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text('Pas de compte ? S\'inscrire'),
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
# PAGE: REGISTER
# ============================================================
cat > lib/presentation/pages/auth/register_page.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthOtpSent) {
            context.push('/otp', extra: state.phone);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Créer un compte',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Rejoignez Flash Deals Abidjan',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),
                if (loading)
                  const Center(child: CircularProgressIndicator())
                else
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(
                              RegisterRequested(
                                fullName: _nameCtrl.text,
                                phone: _phoneCtrl.text,
                                email: _emailCtrl.text,
                                password: _passCtrl.text,
                              ),
                            );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'S\'inscrire',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
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
# PAGE: OTP
# ============================================================
cat > lib/presentation/pages/auth/otp_page.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class OtpPage extends StatefulWidget {
  final String phone;
  const OtpPage({super.key, required this.phone});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _codeCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/home');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Vérification OTP',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Code envoyé au ${widget.phone}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: '000000',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '💡 Code de démo : 123456',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 24),
                if (loading)
                  const Center(child: CircularProgressIndicator())
                else
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        context
                            .read<AuthBloc>()
                            .add(VerifyOtp(_codeCtrl.text));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Vérifier',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
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
# PAGE: PROFILE
# ============================================================
cat > lib/presentation/pages/profile/profile_page.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mon profil')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: Text('Non connecté'));
          }
          final user = state.user;
          return ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                color: Colors.white,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(user.phone,
                        style: const TextStyle(color: Colors.grey)),
                    Text(user.email,
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '🎁 ${user.loyaltyPoints} points fidélité',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _item(context, Icons.receipt_long, 'Mes commandes', () {
                context.push('/orders');
              }),
              _item(context, Icons.location_on, 'Mes adresses', () {}),
              _item(context, Icons.credit_card, 'Moyens de paiement', () {}),
              _item(context, Icons.settings, 'Paramètres', () {}),
              _item(context, Icons.help_outline, 'Aide & support', () {}),
              _item(context, Icons.info_outline, 'À propos', () {}),
              const SizedBox(height: 16),
              _item(context, Icons.logout, 'Se déconnecter', () {
                context.read<AuthBloc>().add(const LogoutRequested());
                context.go('/login');
              }, color: Colors.red),
            ],
          );
        },
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: color ?? AppColors.primary),
        title: Text(
          label,
          style: TextStyle(color: color ?? Colors.black87),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
DART

# ============================================================
# PAGE: ORDERS (historique)
# ============================================================
cat > lib/presentation/pages/orders/orders_page.dart << 'DART'
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Données démo
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
          return Container(
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
          );
        },
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
    GoRoute(path: '/orders', builder: (_, __) => const OrdersPage()),
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

echo "✅ Auth + Profil + Orders créés !"
