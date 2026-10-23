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
