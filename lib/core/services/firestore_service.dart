import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/product_model.dart';
import '../../data/models/user_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ============================================
  // PRODUITS
  // ============================================
  Stream<List<ProductModel>> streamProducts() {
    return _db
        .collection('products')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(_docToProduct).toList());
  }

  Stream<List<ProductModel>> streamFlashDeals() {
    return _db
        .collection('products')
        .where('isFlashDeal', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map(_docToProduct).toList());
  }

  ProductModel _docToProduct(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    if (data['expiryDate'] is Timestamp) {
      data['expiryDate'] =
          (data['expiryDate'] as Timestamp).toDate().toIso8601String();
    }
    return ProductModel.fromJson(data);
  }

  Future<List<ProductModel>> getProducts() async {
    final snap = await _db.collection('products').get();
    return snap.docs.map(_docToProduct).toList();
  }

  Future<ProductModel?> getProduct(String id) async {
    final doc = await _db.collection('products').doc(id).get();
    if (!doc.exists) return null;
    return _docToProduct(doc);
  }

  Future<void> addProduct(ProductModel product) async {
    await _db.collection('products').add({
      'name': product.name,
      'description': product.description,
      'imageUrl': product.imageUrl,
      'categoryId': product.categoryId,
      'storeId': product.storeId,
      'storeName': product.storeName,
      'normalPrice': product.normalPrice,
      'promoPrice': product.promoPrice,
      'stock': product.stock,
      'weightKg': product.weightKg,
      'isFlashDeal': product.isFlashDeal,
      'rating': product.rating,
      'reviewCount': product.reviewCount,
      'expiryDate': Timestamp.fromDate(product.expiryDate),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProduct(ProductModel product) async {
    await _db.collection('products').doc(product.id).update({
      'name': product.name,
      'description': product.description,
      'imageUrl': product.imageUrl,
      'categoryId': product.categoryId,
      'storeName': product.storeName,
      'normalPrice': product.normalPrice,
      'promoPrice': product.promoPrice,
      'stock': product.stock,
      'weightKg': product.weightKg,
      'expiryDate': Timestamp.fromDate(product.expiryDate),
    });
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  // ============================================
  // UTILISATEURS
  // ============================================
  Future<UserModel?> getUserModel(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return UserModel.fromJson(data);
  }

  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set({
      'fullName': user.fullName,
      'phone': user.phone,
      'email': user.email,
      'loyaltyPoints': user.loyaltyPoints,
      'role': 'client',
    }, SetOptions(merge: true));
  }

  // ============================================
  // COMMANDES
  // ============================================
  Future<void> createOrder(Map<String, dynamic> order) async {
    await _db.collection('orders').add({
      ...order,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> streamUserOrders(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  Stream<List<Map<String, dynamic>>> streamAllOrders() {
    return _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // ============================================
  // MAGASINS & CATÉGORIES
  // ============================================
  Stream<List<Map<String, dynamic>>> streamStores() {
    return _db.collection('stores').snapshots().map((snap) => snap.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  Stream<List<Map<String, dynamic>>> streamCategories() {
    return _db.collection('categories').snapshots().map((snap) => snap.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  // ============================================
  // NOTIFICATIONS UTILISATEUR
  // ============================================
  
  /// Stream des notifications d'un utilisateur spécifique
  Stream<List<Map<String, dynamic>>> streamUserNotifications(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Marquer une notification comme lue
  Future<void> markNotificationAsRead(
      String userId, String notificationId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Marquer toutes les notifications comme lues
  Future<void> markAllNotificationsAsRead(String userId) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Créer une notification pour un utilisateur
  Future<void> createUserNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Créer les notifications de démo pour un nouvel utilisateur
  Future<void> seedUserNotifications(String userId) async {
    final batch = _db.batch();
    final col = _db.collection('users').doc(userId).collection('notifications');

    // Notif 1 : non lue
    batch.set(col.doc('welcome'), {
      'title': '🎉 Bienvenue sur Flash Deals !',
      'body': 'Découvrez les meilleurs deals à Abidjan',
      'type': 'promo',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Notif 2 : non lue
    batch.set(col.doc('first_deal'), {
      'title': '🔥 Nouveau deal à Cocody',
      'body': 'Lait Candia à -50% chez Carrefour Cocody',
      'type': 'deal',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    debugPrint('✅ Notifications de bienvenue créées pour $userId');
  }

  // ============================================
  // UTILISATEUR
  // ============================================
  
  /// Mettre à jour le profil utilisateur
  Future<void> updateUserProfile({
    required String userId,
    required String fullName,
    required String phone,
    required String email,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (avatarUrl != null) {
      updates['avatarUrl'] = avatarUrl;
    }

    await _db.collection('users').doc(userId).update(updates);
    debugPrint('✅ Profil mis à jour pour $userId');
  }

  /// Récupérer un utilisateur
  Future<Map<String, dynamic>?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  /// Stream d'un utilisateur (temps réel)
  Stream<Map<String, dynamic>?> streamUser(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    });
  }

  // ============================================
  // FAVORIS
  // ============================================
  Stream<List<Map<String, dynamic>>> streamFavorites(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> toggleFavorite({
    required String userId,
    required String productId,
    required Map<String, dynamic> productData,
  }) async {
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(productId);

    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.delete();
      debugPrint('💔 Retiré des favoris: $productId');
    } else {
      await docRef.set({
        ...productData,
        'addedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('❤️ Ajouté aux favoris: $productId');
    }
  }

  Future<bool> isFavorite({
    required String userId,
    required String productId,
  }) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(productId)
        .get();
    return doc.exists;
  }

  // ============================================
  // ADRESSES
  // ============================================
  Stream<List<Map<String, dynamic>>> streamAddresses(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> addAddress({
    required String userId,
    required Map<String, dynamic> addressData,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .add({
      ...addressData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAddress({
    required String userId,
    required String addressId,
    required Map<String, dynamic> addressData,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(addressId)
        .update({
      ...addressData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAddress({
    required String userId,
    required String addressId,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(addressId)
        .delete();
  }

  Future<void> setDefaultAddress({
    required String userId,
    required String addressId,
  }) async {
    // Retirer tous les défauts
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == addressId});
    }
    await batch.commit();
  }

  // ============================================
  // MOYENS DE PAIEMENT
  // ============================================
  Stream<List<Map<String, dynamic>>> streamPaymentMethods(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> addPaymentMethod({
    required String userId,
    required Map<String, dynamic> paymentData,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .add({
      ...paymentData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePaymentMethod({
    required String userId,
    required String paymentId,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .doc(paymentId)
        .delete();
  }

  Future<void> setDefaultPayment({
    required String userId,
    required String paymentId,
  }) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == paymentId});
    }
    await batch.commit();
  }

  // ============================================
  // CATÉGORIES (CRUD)
  // ============================================

  Future<void> addCategory(Map<String, dynamic> data) async {
    await _db.collection('categories').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await _db.collection('categories').doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }

  /// Compte les produits d'une catégorie
  Future<int> countProductsInCategory(String categoryId) async {
    final snap = await _db
        .collection('products')
        .where('categoryId', isEqualTo: categoryId)
        .count()
        .get();
    return snap.count ?? 0;
  }

  // ============================================
  // MAGASINS (CRUD)
  // ============================================

  Future<void> addStore(Map<String, dynamic> data) async {
    await _db.collection('stores').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStore(String id, Map<String, dynamic> data) async {
    await _db.collection('stores').doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteStore(String id) async {
    await _db.collection('stores').doc(id).delete();
  }

  // ============================================
  // UTILISATEURS
  // ============================================
  Stream<List<Map<String, dynamic>>> streamUsers() {
    return _db
        .collection('users')
        .orderBy('fullName')
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    await _db.collection('users').doc(userId).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteUser(String userId) async {
    await _db.collection('users').doc(userId).delete();
  }

  // ============================================
  // DASHBOARD STATS (temps réel)
  // ============================================
  Stream<Map<String, dynamic>> streamDashboardStats() {
    // Combine plusieurs streams
    return _db
        .collection('orders')
        .snapshots()
        .asyncMap((ordersSnap) async {
      // Calculer les commandes et revenus
      int totalOrders = 0;
      double totalRevenue = 0;
      int inDelivery = 0;

      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'pending';
        final total = (data['total'] as num?)?.toDouble() ?? 0;

        totalOrders++;
        totalRevenue += total;

        if (status == 'onTheWay' || status == 'preparing') {
          inDelivery++;
        }
      }

      // Compter les produits
      final productsSnap = await _db.collection('products').count().get();

      // Compter les clients
      final clientsSnap = await _db
          .collection('users')
          .where('role', isEqualTo: 'client')
          .count()
          .get();

      // Compter les catégories
      final categoriesSnap =
          await _db.collection('categories').count().get();

      return {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'inDelivery': inDelivery,
        'totalProducts': productsSnap.count ?? 0,
        'totalClients': clientsSnap.count ?? 0,
        'totalCategories': categoriesSnap.count ?? 0,
      };
    });
  }

  // ============================================
  // LIVRAISONS (HISTORIQUE)
  // ============================================
  Stream<List<Map<String, dynamic>>> streamDeliveries() {
    return _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Stream filtré par statut de livraison
  Stream<List<Map<String, dynamic>>> streamDeliveriesByStatus(
      String status) {
    return _db
        .collection('orders')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Marquer une livraison comme "livrée"
  Future<void> markDelivered(String orderId) async {
    await _db.collection('orders').doc(orderId).update({
      'status': 'delivered',
      'deliveredAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Assigner un livreur
  Future<void> assignCourier({
    required String orderId,
    required String courierName,
    required String courierPhone,
  }) async {
    await _db.collection('orders').doc(orderId).update({
      'courier': {
        'name': courierName,
        'phone': courierPhone,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
