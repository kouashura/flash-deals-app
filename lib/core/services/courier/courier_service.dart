import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../domain/entities/courier.dart';

class CourierService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Inscription d'un nouveau livreur
  static Future<String> registerCourier({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String city,
    required String zone,
    required String address,
    required VehicleType vehicleType,
    required String vehiclePlate,
    required String idCardNumber,
    String? idCardUrl,
    String? photoUrl,
    String? licenseUrl,
  }) async {
    try {
      // 1. Créer le compte Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      // 2. Créer le profil dans Firestore
      await _db.collection('couriers').doc(uid).set({
        'fullName': fullName.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'city': city.trim(),
        'zone': zone.trim(),
        'address': address.trim(),
        'vehicleType': vehicleType.name,
        'vehiclePlate': vehiclePlate.trim(),
        'idCardNumber': idCardNumber.trim(),
        'idCardUrl': idCardUrl ?? '',
        'photoUrl': photoUrl ?? '',
        'licenseUrl': licenseUrl ?? '',
        'status': CourierStatus.pending.name,
        'isAvailable': false,
        'totalDeliveries': 0,
        'totalEarnings': 0.0,
        'rating': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Créer le doc dans users avec role courier
      await _db.collection('users').doc(uid).set({
        'fullName': fullName.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'role': 'courier',
        'loyaltyPoints': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Livreur inscrit: $uid');
      return uid;
    } on FirebaseAuthException catch (e) {
      throw Exception(_authErrorMessage(e.code));
    }
  }

  /// Connexion livreur
  static Future<Courier?> loginCourier({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      final courier = await getCourier(uid);

      if (courier == null) {
        await _auth.signOut();
        throw Exception('Profil livreur introuvable');
      }

      return courier;
    } on FirebaseAuthException catch (e) {
      throw Exception(_authErrorMessage(e.code));
    }
  }

  /// Récupérer un livreur
  static Future<Courier?> getCourier(String uid) async {
    final doc = await _db.collection('couriers').doc(uid).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    return _courierFromMap(uid, data);
  }

  /// Stream du livreur connecté
  static Stream<Courier?> streamCurrentCourier() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    return _db.collection('couriers').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _courierFromMap(uid, doc.data()!);
    });
  }

  /// Mettre à jour la disponibilité
  static Future<void> setAvailability(bool available) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('couriers').doc(uid).update({
      'isAvailable': available,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Déconnexion
  static Future<void> logout() async {
    await _auth.signOut();
  }

  /// Convertir Map → Courier
  static Courier _courierFromMap(String uid, Map<String, dynamic> data) {
    return Courier(
      id: uid,
      fullName: data['fullName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      city: data['city'] as String? ?? 'Abidjan',
      zone: data['zone'] as String? ?? '',
      address: data['address'] as String? ?? '',
      vehicleType: VehicleType.values.firstWhere(
        (e) => e.name == data['vehicleType'],
        orElse: () => VehicleType.motorcycle,
      ),
      vehiclePlate: data['vehiclePlate'] as String? ?? '',
      idCardNumber: data['idCardNumber'] as String? ?? '',
      idCardUrl: data['idCardUrl'] as String?,
      photoUrl: data['photoUrl'] as String?,
      licenseUrl: data['licenseUrl'] as String?,
      status: CourierStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => CourierStatus.pending,
      ),
      isAvailable: data['isAvailable'] as bool? ?? false,
      totalDeliveries: data['totalDeliveries'] as int? ?? 0,
      totalEarnings: (data['totalEarnings'] as num?)?.toDouble() ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
    );
  }

  static String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun compte avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'weak-password':
        return 'Mot de passe trop faible (6 caractères min)';
      case 'invalid-email':
        return 'Email invalide';
      default:
        return 'Erreur : $code';
    }
  }
}
