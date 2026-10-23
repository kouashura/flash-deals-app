import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/wallet_service.dart';
import '../../data/models/wallet_model.dart';
import 'auth_provider.dart';

final walletServiceProvider = Provider<WalletService>((ref) {
  return WalletService();
});

final walletStreamProvider = StreamProvider.autoDispose<WalletModel>((ref) {
  final user = ref.watch(authUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(walletServiceProvider).getWalletStream(user.uid);
});

final transactionsStreamProvider =
    StreamProvider.autoDispose<List<WalletTransaction>>((ref) {
  final user = ref.watch(authUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(walletServiceProvider).getTransactionsStream(user.uid);
});
