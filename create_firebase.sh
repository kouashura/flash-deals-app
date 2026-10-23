#!/bin/bash
echo "🔥 Création de l'intégration Firebase..."

# ============================================================
# FIREBASE SERVICE (auth + firestore)
# ============================================================
cat > lib/core/services/firebase_service.dart << 'DART'
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _messaging = FirebaseMessaging.instance;

  // ============ AUTH ============
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ============ FIRESTORE ============
  CollectionReference get products =>
      _firestore.collection('products');
  CollectionReference get orders => _firestore.collection('orders');
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get stores => _firestore.collection('stores');
  CollectionReference get notifications =>
      _firestore.collection('notifications');

  // ============ NOTIFICATIONS ============
  Future<String?> getFcmToken() async {
    return await _messaging.getToken();
  }

  Future<void> requestNotificationPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }
}
DART

# ============================================================
# PRODUCT SERVICE (Firestore)
# ============================================================
cat > lib/core/services/product_service.dart << 'DART'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/product_model.dart';

class ProductService {
  final _firestore = FirebaseFirestore.instance;

  Future<List<ProductModel>> getProducts() async {
    final snapshot = await _firestore.collection('products').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      if (data['expiryDate'] is Timestamp) {
        data['expiryDate'] =
            (data['expiryDate'] as Timestamp).toDate().toIso8601String();
      }
      return ProductModel.fromJson(data);
    }).toList();
  }
}
DART

# ============================================================
# MAIN (init Firebase)
# ============================================================
cat > lib/main.dart << 'DART'
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/di/injection_container.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Dependencies
  await initDependencies();

  runApp(const FlashDealsApp());
}
DART

# ============================================================
# DI (ajout FirebaseService + ProductService)
# ============================================================
cat > lib/core/di/injection_container.dart << 'DART'
import 'package:get_it/get_it.dart';
import '../services/storage_service.dart';
import '../services/firebase_service.dart';
import '../services/product_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  final storage = StorageService();
  await storage.init();
  sl.registerSingleton<StorageService>(storage);

  sl.registerSingleton<FirebaseService>(FirebaseService());
  sl.registerSingleton<ProductService>(ProductService());
}
DART

echo "✅ Firebase intégré !"
