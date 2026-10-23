import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LoyaltyService {
  /// 1 point par 100 FCFA
  static const int _pointsPerHundred = 1;

  /// Calcule les points gagnés pour un montant
  static int calculatePoints(double amount) {
    return (amount / 100).floor() * _pointsPerHundred;
  }

  /// Ajoute les points au client
  static Future<void> addPoints({
    required String userId,
    required double amount,
    required String orderId,
  }) async {
    final points = calculatePoints(amount);
    if (points <= 0) return;

    final db = FirebaseFirestore.instance;

    // 1. Mettre à jour le total
    await db.collection('users').doc(userId).update({
      'loyaltyPoints': FieldValue.increment(points),
    });

    // 2. Historique
    await db
        .collection('users')
        .doc(userId)
        .collection('loyalty_history')
        .add({
      'points': points,
      'amount': amount,
      'orderId': orderId,
      'type': 'earned',
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ $points points ajoutés à $userId');
  }

  /// Stream de l'historique
  static Stream<List<Map<String, dynamic>>> streamHistory(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('loyalty_history')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }
}
