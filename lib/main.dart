import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/di/injection_container.dart';
import 'core/services/push_notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🌍 Initialiser la locale française (pour les dates)
  await initializeDateFormatting('fr_FR', null);

  // Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Notifications push OneSignal
  await PushNotificationService.init();

  // Dependencies
  await initDependencies();

  runApp(
    const ProviderScope(
      child: FlashDealsApp(),
    ),
  );
}
