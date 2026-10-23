import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/firestore_service.dart';
import '../../../domain/entities/notification.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final _firestore = FirestoreService();
  StreamSubscription? _subscription;

  NotificationBloc() : super(const NotificationState()) {
    on<LoadNotifications>(_onLoad);
    on<MarkAsRead>(_onRead);
    on<MarkAllAsRead>(_onAllRead);
    on<AddNotification>(_onAdd);
    on<UserChanged>(_onUserChanged);
    on<_InternalUpdate>(_onInternalUpdate);
  }

  /// Traite les mises à jour venant du stream Firestore
  void _onInternalUpdate(
    _InternalUpdate event,
    Emitter<NotificationState> emit,
  ) {
    emit(NotificationState(notifications: event.list));
  }

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  /// Charge les notifications de l'utilisateur connecté
  void _onLoad(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    final uid = _userId;

    // Annuler l'ancien stream
    await _subscription?.cancel();
    _subscription = null;

    // Si pas connecté → vider les notifications
    if (uid == null) {
      debugPrint('📭 Pas connecté → notifications vidées');
      emit(const NotificationState());
      return;
    }

    debugPrint('📬 Abonnement aux notifications de $uid');

    // Seed les notifs de bienvenue si c'est la première fois
    await _seedIfFirstTime(uid);

    // Écouter les notifications en temps réel
    _subscription = _firestore.streamUserNotifications(uid).listen(
      (docs) {
        final notifications = docs.map((doc) {
          final createdAt = doc['createdAt'];
          return AppNotification(
            id: doc['id'] as String,
            title: doc['title'] as String? ?? '',
            body: doc['body'] as String? ?? '',
            type: doc['type'] as String? ?? 'general',
            createdAt: createdAt is Timestamp
                ? createdAt.toDate()
                : DateTime.now(),
            isRead: doc['isRead'] as bool? ?? false,
          );
        }).toList();

        if (!isClosed) {
          add(_InternalUpdate(notifications));
        }
      },
      onError: (error) {
        debugPrint('❌ Erreur stream notifications: $error');
      },
    );
  }

  /// Réagit aux changements d'utilisateur (connexion/déconnexion)
  void _onUserChanged(UserChanged event, Emitter<NotificationState> emit) {
    add(const LoadNotifications());
  }

  /// Crée les notifications de bienvenue si c'est la première connexion
  Future<void> _seedIfFirstTime(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        debugPrint('🌱 Première connexion → création des notifs de démo');
        await _firestore.seedUserNotifications(uid);
      }
    } catch (e) {
      debugPrint('❌ Erreur seed notifs: $e');
    }
  }

  /// Marque UNE notif comme lue (Firestore)
  Future<void> _onRead(
    MarkAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final uid = _userId;
    if (uid == null) return;

    // Mise à jour optimiste (instantanée)
    final updated = state.notifications.map((n) {
      if (n.id == event.id && !n.isRead) return n.copyWith(isRead: true);
      return n;
    }).toList();
    emit(state.copyWith(notifications: updated));

    // Persister dans Firestore
    try {
      await _firestore.markNotificationAsRead(uid, event.id);
      debugPrint('✅ Notif ${event.id} marquée lue');
    } catch (e) {
      debugPrint('❌ Erreur mark as read: $e');
    }
  }

  /// Marque TOUTES comme lues
  Future<void> _onAllRead(
    MarkAllAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final uid = _userId;
    if (uid == null) return;

    // Mise à jour optimiste
    final updated = state.notifications
        .map((n) => n.isRead ? n : n.copyWith(isRead: true))
        .toList();
    emit(state.copyWith(notifications: updated));

    try {
      await _firestore.markAllNotificationsAsRead(uid);
      debugPrint('✅ Toutes les notifs marquées lues');
    } catch (e) {
      debugPrint('❌ Erreur mark all: $e');
    }
  }

  /// Ajoute une notification reçue (ex: push OneSignal)
  void _onAdd(AddNotification event, Emitter<NotificationState> emit) {
    final uid = _userId;
    final updated = [event.notification, ...state.notifications];
    emit(state.copyWith(notifications: updated));

    // Persister dans Firestore
    if (uid != null) {
      _firestore.createUserNotification(
        userId: uid,
        title: event.notification.title,
        body: event.notification.body,
        type: event.notification.type,
      );
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

/// Événement interne pour les mises à jour du stream Firestore
class _InternalUpdate extends NotificationEvent {
  final List<AppNotification> list;
  const _InternalUpdate(this.list);

  @override
  List<Object?> get props => [list];
}
