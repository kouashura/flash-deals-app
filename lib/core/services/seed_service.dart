import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service qui initialise Firestore avec toutes les collections et documents de démo.
/// ⚠️ À exécuter UNE SEULE FOIS en développement.
class SeedService {
  final _db = FirebaseFirestore.instance;

  Future<void> seedAll() async {
    try {
      debugPrint('🌱 Démarrage du seed Firebase...');
      await _seedCategories();
      await _seedStores();
      await _seedProducts();
      await _seedAdminUser();
      await _seedNotifications();
      debugPrint('✅ Seed terminé avec succès !');
    } catch (e) {
      debugPrint('❌ Erreur seed: $e');
      rethrow;
    }
  }

  Future<void> _seedCategories() async {
    final categories = [
      {'id': '1', 'name': 'Laitier', 'emoji': '🥛'},
      {'id': '2', 'name': 'Viande', 'emoji': '🥩'},
      {'id': '3', 'name': 'Boulangerie', 'emoji': '🍞'},
      {'id': '4', 'name': 'Boissons', 'emoji': '🥤'},
      {'id': '5', 'name': 'Hygiène', 'emoji': '🧴'},
      {'id': '6', 'name': 'Épicerie', 'emoji': '🥫'},
    ];

    final batch = _db.batch();
    for (final cat in categories) {
      batch.set(_db.collection('categories').doc(cat['id'] as String), {
        'name': cat['name'],
        'emoji': cat['emoji'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    debugPrint('  ✅ ${categories.length} catégories créées');
  }

  Future<void> _seedStores() async {
    final stores = [
      {
        'id': 's1',
        'name': 'Carrefour Cocody',
        'zone': 'Cocody',
        'address': 'Cocody, Boulevard Latrille',
        'latitude': 5.3561,
        'longitude': -3.9876,
      },
      {
        'id': 's2',
        'name': 'Prosuma Plateau',
        'zone': 'Plateau',
        'address': 'Plateau, Avenue Chardy',
        'latitude': 5.3244,
        'longitude': -4.0167,
      },
      {
        'id': 's3',
        'name': 'Sococié Marcory',
        'zone': 'Marcory',
        'address': 'Marcory, Boulevard VGE',
        'latitude': 5.2967,
        'longitude': -3.9909,
      },
      {
        'id': 's4',
        'name': 'Bon Prix Yopougon',
        'zone': 'Yopougon',
        'address': 'Yopougon, Siporex',
        'latitude': 5.3411,
        'longitude': -4.0761,
      },
    ];

    final batch = _db.batch();
    for (final store in stores) {
      batch.set(_db.collection('stores').doc(store['id'] as String), {
        'name': store['name'],
        'zone': store['zone'],
        'address': store['address'],
        'latitude': store['latitude'],
        'longitude': store['longitude'],
        'logoUrl': '',
        'rating': 4.5,
        'isOpen': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    debugPrint('  ✅ ${stores.length} magasins créés');
  }

  Future<void> _seedProducts() async {
    final now = DateTime.now();
    final products = [
      {
        'name': 'Lait Candia 1L',
        'description': 'Lait demi-écrémé UHT',
        'categoryId': '1',
        'storeId': 's1',
        'storeName': 'Carrefour Cocody',
        'normalPrice': 1200,
        'promoPrice': 600,
        'stock': 3,
        'weightKg': 1.0,
        'days': 3,
        'rating': 4.5,
        'reviewCount': 12,
      },
      {
        'name': 'Yaourt Activia x4',
        'description': 'Yaourt nature brassé',
        'categoryId': '1',
        'storeId': 's2',
        'storeName': 'Prosuma Plateau',
        'normalPrice': 2500,
        'promoPrice': 1500,
        'stock': 8,
        'weightKg': 0.5,
        'days': 5,
        'rating': 4.2,
        'reviewCount': 8,
      },
      {
        'name': 'Steak haché 500g',
        'description': 'Bœuf frais haché',
        'categoryId': '2',
        'storeId': 's1',
        'storeName': 'Carrefour Cocody',
        'normalPrice': 3500,
        'promoPrice': 2000,
        'stock': 2,
        'weightKg': 0.5,
        'days': 1,
        'rating': 4.8,
        'reviewCount': 25,
      },
      {
        'name': 'Pain complet',
        'description': 'Pain complet artisanal',
        'categoryId': '3',
        'storeId': 's3',
        'storeName': 'Sococié Marcory',
        'normalPrice': 800,
        'promoPrice': 400,
        'stock': 15,
        'weightKg': 0.4,
        'days': 2,
        'rating': 4.0,
        'reviewCount': 5,
      },
      {
        'name': 'Jus d\'orange 1L',
        'description': '100% pur jus sans sucre ajouté',
        'categoryId': '4',
        'storeId': 's2',
        'storeName': 'Prosuma Plateau',
        'normalPrice': 1800,
        'promoPrice': 1000,
        'stock': 10,
        'weightKg': 1.1,
        'days': 6,
        'rating': 4.3,
        'reviewCount': 18,
      },
      {
        'name': 'Fromage râpé 200g',
        'description': 'Emmental râpé',
        'categoryId': '1',
        'storeId': 's1',
        'storeName': 'Carrefour Cocody',
        'normalPrice': 2200,
        'promoPrice': 1200,
        'stock': 4,
        'weightKg': 0.2,
        'days': 4,
        'rating': 4.6,
        'reviewCount': 10,
      },
      {
        'name': 'Eau minérale 1.5L',
        'description': 'Eau minérale naturelle',
        'categoryId': '4',
        'storeId': 's4',
        'storeName': 'Bon Prix Yopougon',
        'normalPrice': 500,
        'promoPrice': 250,
        'stock': 24,
        'weightKg': 1.5,
        'days': 30,
        'rating': 4.7,
        'reviewCount': 40,
      },
      {
        'name': 'Savon Palmolive',
        'description': 'Savon de toilette 100g',
        'categoryId': '5',
        'storeId': 's2',
        'storeName': 'Prosuma Plateau',
        'normalPrice': 700,
        'promoPrice': 400,
        'stock': 12,
        'weightKg': 0.15,
        'days': 60,
        'rating': 4.4,
        'reviewCount': 15,
      },
    ];

    final batch = _db.batch();
    for (final p in products) {
      final doc = _db.collection('products').doc();
      batch.set(doc, {
        'name': p['name'],
        'description': p['description'],
        'imageUrl': '',
        'categoryId': p['categoryId'],
        'storeId': p['storeId'],
        'storeName': p['storeName'],
        'normalPrice': p['normalPrice'],
        'promoPrice': p['promoPrice'],
        'stock': p['stock'],
        'weightKg': p['weightKg'],
        'isFlashDeal': true,
        'rating': p['rating'],
        'reviewCount': p['reviewCount'],
        'expiryDate':
            Timestamp.fromDate(now.add(Duration(days: p['days'] as int))),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    debugPrint('  ✅ ${products.length} produits créés');
  }

  Future<void> _seedAdminUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('  ⚠️ Aucun utilisateur connecté — admin ignoré');
      return;
    }

    await _db.collection('users').doc(currentUser.uid).set({
      'fullName': 'Admin Flash Deals',
      'phone': '+225 07 00 00 00 00',
      'email': currentUser.email ?? 'admin@flashdeals.ci',
      'loyaltyPoints': 0,
      'role': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint('  ✅ Admin enregistré (uid: ${currentUser.uid})');
  }

  Future<void> _seedNotifications() async {
    final notifs = [
      {
        'title': '🔥 Nouveau deal à Cocody',
        'body': 'Lait Candia à -50% chez Carrefour Cocody',
        'type': 'deal',
      },
      {
        'title': '🎁 100 points offerts',
        'body': 'Félicitations ! Vous avez gagné 100 points fidélité',
        'type': 'promo',
      },
      {
        'title': '📦 Commande en route',
        'body': 'Votre commande #FD-002 est en cours de livraison',
        'type': 'order',
      },
    ];

    final batch = _db.batch();
    for (final n in notifs) {
      final doc = _db.collection('notifications').doc();
      batch.set(doc, {
        'title': n['title'],
        'body': n['body'],
        'type': n['type'],
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    debugPrint('  ✅ ${notifs.length} notifications créées');
  }

  Future<void> clearAll() async {
    final collections = ['products', 'categories', 'stores', 'notifications'];
    for (final c in collections) {
      final snap = await _db.collection(c).get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
      debugPrint('  🗑️ Collection $c vidée');
    }
  }
}
