import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/services/firestore_service.dart';
import '../../../data/models/user_model.dart';

// ============ EVENTS ============
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  const LoadProfile();
}

class UpdateProfileInfo extends ProfileEvent {
  final String fullName;
  final String phone;
  final String email;
  const UpdateProfileInfo({
    required this.fullName,
    required this.phone,
    required this.email,
  });
  @override
  List<Object?> get props => [fullName, phone, email];
}

class UpdateAvatar extends ProfileEvent {
  final String avatarUrl;
  const UpdateAvatar(this.avatarUrl);
  @override
  List<Object?> get props => [avatarUrl];
}

// ============ STATES ============
abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final UserModel user;
  const ProfileLoaded(this.user);
  @override
  List<Object?> get props => [user];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}

// ============ BLOC ============
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final _firestore = FirestoreService();

  ProfileBloc() : super(const ProfileInitial()) {
    on<LoadProfile>(_onLoad);
    on<UpdateProfileInfo>(_onUpdateInfo);
    on<UpdateAvatar>(_onUpdateAvatar);
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _onLoad(LoadProfile event, Emitter<ProfileState> emit) async {
    final uid = _uid;
    if (uid == null) {
      emit(const ProfileError('Non connecté'));
      return;
    }

    emit(const ProfileLoading());
    try {
      final user = await _firestore.getUserModel(uid);
      if (user != null) {
        emit(ProfileLoaded(user));
      } else {
        emit(const ProfileError('Profil introuvable'));
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement profil: $e');
      emit(ProfileError('Erreur : $e'));
    }
  }

  Future<void> _onUpdateInfo(
    UpdateProfileInfo event,
    Emitter<ProfileState> emit,
  ) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _firestore.updateUserProfile(
        userId: uid,
        fullName: event.fullName,
        phone: event.phone,
        email: event.email,
      );
      debugPrint('✅ Profil mis à jour');
      add(const LoadProfile());
    } catch (e) {
      debugPrint('❌ Erreur mise à jour: $e');
      emit(ProfileError('Erreur : $e'));
    }
  }

  Future<void> _onUpdateAvatar(
    UpdateAvatar event,
    Emitter<ProfileState> emit,
  ) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _firestore.updateUserProfile(
        userId: uid,
        fullName: '',
        phone: '',
        email: '',
        avatarUrl: event.avatarUrl,
      );
      add(const LoadProfile());
    } catch (e) {
      debugPrint('❌ Erreur avatar: $e');
      emit(ProfileError('Erreur : $e'));
    }
  }
}
