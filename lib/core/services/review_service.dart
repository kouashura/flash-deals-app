import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ReviewService {
  static final _db = FirebaseFirestore.instance;

  /// Stream des avis d'un produit
  static Stream<List<Map<String, dynamic>>> streamProductReviews(
      String productId) {
    return _db
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Ajoute un avis
  static Future<void> addReview({
    required String productId,
    required String orderId,
    required double rating,
    required String comment,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Non connecté');

    // Récupérer le nom
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final userName =
        userDoc.data()?['fullName'] as String? ?? 'Client';

    // 1. Créer l'avis dans la sous-collection du produit
    await _db
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .add({
      'userId': user.uid,
      'userName': userName,
      'rating': rating,
      'comment': comment.trim(),
      'orderId': orderId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Recalculer la moyenne du produit
    await _updateProductRating(productId);

    // 3. Marquer la commande comme "évaluée"
    await _db.collection('orders').doc(orderId).update({
      'reviewed': true,
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ Avis ajouté pour $productId');
  }

  /// Recalcule la moyenne d'un produit
  static Future<void> _updateProductRating(String productId) async {
    final reviewsSnap = await _db
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .get();

    if (reviewsSnap.docs.isEmpty) return;

    double total = 0;
    for (final doc in reviewsSnap.docs) {
      total += (doc.data()['rating'] as num?)?.toDouble() ?? 0;
    }

    final avg = total / reviewsSnap.docs.length;

    await _db.collection('products').doc(productId).update({
      'rating': double.parse(avg.toStringAsFixed(1)),
      'reviewCount': reviewsSnap.docs.length,
    });
  }

  /// Vérifie si l'utilisateur a déjà noté un produit
  static Future<bool> hasUserReviewed({
    required String productId,
    required String userId,
  }) async {
    final snap = await _db
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
  }
}
