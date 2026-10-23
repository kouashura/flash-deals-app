import 'package:get_it/get_it.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import '../services/locale_service.dart';
import '../services/firebase_service.dart';
import '../services/product_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ─── Storage ───
  final storage = StorageService();
  await storage.init();
  sl.registerSingleton<StorageService>(storage);

  // ─── Theme (mode sombre) ───
  final themeService = ThemeService();
  await themeService.init();
  sl.registerSingleton<ThemeService>(themeService);

  // ─── Locale (langue) ───
  final localeService = LocaleService();
  await localeService.init();
  sl.registerSingleton<LocaleService>(localeService);

  // ─── Firebase ───
  sl.registerSingleton<FirebaseService>(FirebaseService());
  sl.registerSingleton<ProductService>(ProductService());
}
