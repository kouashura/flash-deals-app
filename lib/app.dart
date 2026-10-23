import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/dark_theme.dart';
import 'core/di/injection_container.dart';
import 'core/services/theme_service.dart';
import 'core/services/locale_service.dart';
import 'presentation/blocs/cart/cart_bloc.dart';
import 'presentation/blocs/cart/cart_event.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/notification/notification_bloc.dart';
import 'presentation/blocs/notification/notification_event.dart';
import 'presentation/blocs/delivery/delivery_bloc.dart';

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
        BlocProvider(create: (_) => DeliveryBloc()),
      ],
      child: AnimatedBuilder(
        animation: Listenable.merge([
          sl<ThemeService>(),
          sl<LocaleService>(),
        ]),
        builder: (context, _) {
          return MaterialApp.router(
            title: 'Flash Deals',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: DarkTheme.theme,
            themeMode: sl<ThemeService>().themeMode,
            locale: sl<LocaleService>().locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('fr'),
              Locale('en'),
            ],
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
