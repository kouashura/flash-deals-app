import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/wallet_model.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<WalletModel> getWalletStream(String uid) {
    return _firestore.collection('deals_wallets').doc(uid).snapshots().map((doc) {
      if (!doc.exists) {
        return const WalletModel(balance: 0.0);
      }
      return WalletModel.fromJson(doc.data()!);
    });
  }

  Stream<List<WalletTransaction>> getTransactionsStream(String uid) {
    return _firestore
        .collection('deals_wallets')
        .doc(uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WalletTransaction.fromJson(doc.data()))
            .toList());
  }

  Future<String?> payWithWallet({
    required String uid,
    required double amount,
    required String orderId,
    required String description,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final walletRef = _firestore.collection('deals_wallets').doc(uid);
        final walletSnapshot = await transaction.get(walletRef);

        if (!walletSnapshot.exists) {
          throw Exception("Wallet introuvable");
        }

        final currentBalance =
            (walletSnapshot.data()!['balance'] as num).toDouble();

        if (currentBalance < amount) {
          throw Exception("Solde insuffisant");
        }

        transaction.update(walletRef, {
          'balance': currentBalance - amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final txRef = walletRef.collection('transactions').doc();
        transaction.set(txRef, {
          'id': txRef.id,
          'type': 'debit',
          'amount': amount,
          'description': description,
          'date': FieldValue.serverTimestamp(),
          'status': 'success',
        });
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
