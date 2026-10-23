import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final StorageService _storage;
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  AuthBloc(this._storage) : super(const AuthInitial()) {
    on<CheckAuthStatus>(_onCheck);
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<LogoutRequested>(_onLogout);
    on<UpdateProfile>(_onUpdateProfile);
  }

  /// Vérifie si un utilisateur est déjà connecté
  Future<void> _onCheck(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      emit(const AuthUnauthenticated());
      return;
    }

    try {
      final user = await _loadUser(firebaseUser.uid);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  /// Connexion avec email/password
  Future<void> _onLogin(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );

      final user = await _loadUser(credential.user!.uid);
      await PushNotificationService.onUserSignedIn();
      emit(AuthAuthenticated(user));
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_authErrorMessage(e.code)));
    } catch (e) {
      emit(AuthError('Erreur : $e'));
    }
  }

  /// Inscription (création Firebase Auth + doc Firestore)
  Future<void> _onRegister(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );

      final uid = credential.user!.uid;

      // Créer le profil dans Firestore
      final user = UserModel(
        id: uid,
        fullName: event.fullName.trim(),
        phone: event.phone.trim(),
        email: event.email.trim(),
        loyaltyPoints: 50,
      );

      await _db.collection('users').doc(uid).set({
        'fullName': user.fullName,
        'phone': user.phone,
        'email': user.email,
        'loyaltyPoints': user.loyaltyPoints,
        'role': 'client',
        'createdAt': FieldValue.serverTimestamp(),
      });

      emit(AuthAuthenticated(user));
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_authErrorMessage(e.code)));
    } catch (e) {
      emit(AuthError('Erreur : $e'));
    }
  }

  /// Déconnexion
  Future<void> _onLogout(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await PushNotificationService.onUserSignedOut();
    await _auth.signOut();
    await _storage.clearUser();
    await _storage.clearToken();
    emit(const AuthUnauthenticated());
  }

  /// Mettre à jour le profil
  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = state;
    if (currentUser is! AuthAuthenticated) return;

    try {
      final updates = <String, dynamic>{
        'fullName': event.fullName.trim(),
        'phone': event.phone.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (event.avatarUrl != null) {
        updates['avatarUrl'] = event.avatarUrl;
      }

      await _db.collection('users').doc(currentUser.user.id).update(updates);

      final updated = UserModel(
        id: currentUser.user.id,
        fullName: event.fullName.trim(),
        phone: event.phone.trim(),
        email: currentUser.user.email,
        avatarUrl: event.avatarUrl ?? currentUser.user.avatarUrl,
        loyaltyPoints: currentUser.user.loyaltyPoints,
      );

      emit(AuthAuthenticated(updated));
      debugPrint('✅ Profil mis à jour');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour: $e');
      emit(AuthError('Erreur mise à jour : $e'));
    }
  }

  /// Charge l'utilisateur depuis Firestore
  Future<UserModel> _loadUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) {
      // Utilisateur Auth sans doc Firestore
      final firebaseUser = _auth.currentUser!;
      return UserModel(
        id: uid,
        fullName: firebaseUser.email?.split('@').first ?? 'Utilisateur',
        phone: '',
        email: firebaseUser.email ?? '',
      );
    }

    final data = doc.data()!;
    data['id'] = doc.id;
    return UserModel.fromJson(data);
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun compte avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'invalid-email':
        return 'Email invalide';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'weak-password':
        return 'Mot de passe trop faible (6 caractères min)';
      case 'user-disabled':
        return 'Ce compte est désactivé';
      case 'network-request-failed':
        return 'Erreur réseau — vérifiez votre connexion';
      default:
        return 'Erreur d\'authentification ($code)';
    }
  }
}
