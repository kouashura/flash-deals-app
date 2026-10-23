import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'loyalty_service.dart';
import '../../data/models/order_model.dart';
import '../../domain/entities/order.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;

  Future<String> createOrder(OrderModel order) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    // Génère un ID anonyme si pas de compte Firebase Auth
    final userId = firebaseUser?.uid ??
        'guest_${DateTime.now().millisecondsSinceEpoch}';

    final userName = firebaseUser?.displayName ??
        firebaseUser?.email ??
        'Client invité';

    final docRef = await _db.collection('orders').add({
      'userId': userId,
      'userName': userName,
      'isGuest': firebaseUser == null,
      'items': order.items.map((item) {
        return {
          'productId': item.product.id,
          'name': item.product.name,
          'imageUrl': item.product.imageUrl,
          'price': item.unitPrice,
          'quantity': item.quantity,
          'total': item.lineTotal,
        };
      }).toList(),
      'address': {
        'label': order.address.label,
        'fullAddress': order.address.fullAddress,
        'zone': order.address.zone,
        'latitude': order.address.latitude,
        'longitude': order.address.longitude,
      },
      'delivery': {
        'fee': order.delivery.fee,
        'zone': order.delivery.zone,
        'timeSlot': order.delivery.timeSlot,
        'status': order.delivery.status.name,
      },
      'payment': {
        'method': order.payment.method.name,
        'amount': order.payment.amount,
        'status': order.payment.status.name,
        'transactionId': order.payment.transactionId ?? '',
      },
      'subtotal': order.subtotal,
      'total': order.total,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ✅ GAGNER DES POINTS FIDÉLITÉ
    if (firebaseUser != null) {
      try {
        await LoyaltyService.addPoints(
          userId: firebaseUser.uid,
          amount: order.total,
          orderId: docRef.id,
        );
      } catch (e) {
        debugPrint('❌ Erreur points fidélité: $e');
      }
    }

    return docRef.id;
  }

  Future<Map<String, dynamic>?> getOrder(String orderId) async {
    final doc = await _db.collection('orders').doc(orderId).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  /// Stream des commandes de l'utilisateur connecté
  /// En mode invité, on retourne un stream vide
  Stream<List<Map<String, dynamic>>> streamUserOrders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Pas connecté → renvoyer toutes les commandes récentes
      // (comportement simplifié pour le dev)
      return _db
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList());
    }

    return _db
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      list.sort((a, b) {
        final aDate = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
        final bDate = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  Stream<List<Map<String, dynamic>>> streamAllOrders() {
    return _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    // 1. Mettre à jour le statut
    await _db.collection('orders').doc(orderId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Récupérer les infos de la commande
    final orderDoc = await _db.collection('orders').doc(orderId).get();
    if (!orderDoc.exists) return;

    final orderData = orderDoc.data()!;
    final userId = orderData['userId'] as String?;
    if (userId == null) return;

    // 3. Créer la notification pour le client
    await _notifyClient(
      userId: userId,
      orderId: orderId,
      status: status,
    );
  }

  /// Crée une notification pour le client lors d'un changement de statut
  Future<void> _notifyClient({
    required String userId,
    required String orderId,
    required OrderStatus status,
  }) async {
    // Message selon le statut
    final messages = {
      OrderStatus.confirmed: {
        'title': '✅ Commande confirmée',
        'body': 'Votre commande #${orderId.substring(0, 8)} a été confirmée.',
        'type': 'order',
      },
      OrderStatus.preparing: {
        'title': '📦 En préparation',
        'body': 'Votre colis est en cours de préparation.',
        'type': 'order',
      },
      OrderStatus.onTheWay: {
        'title': '🚚 En cours de livraison',
        'body': 'Votre livreur est en route vers vous !',
        'type': 'order',
      },
      OrderStatus.delivered: {
        'title': '🎉 Colis livré !',
        'body': 'Merci pour votre commande. À bientôt !',
        'type': 'order',
      },
      OrderStatus.cancelled: {
        'title': '❌ Commande annulée',
        'body': 'Votre commande a été annulée.',
        'type': 'order',
      },
    };

    final msg = messages[status];
    if (msg == null) return;

    // Créer la notif dans users/{userId}/notifications
    await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': msg['title'],
      'body': msg['body'],
      'type': msg['type'],
      'isRead': false,
      'orderId': orderId,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('📬 Notif créée pour $userId (${status.name})');
  }
}
