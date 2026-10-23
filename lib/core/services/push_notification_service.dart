import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Service de notifications push via OneSignal
class PushNotificationService {
  static const String _oneSignalAppId =
      'c8659515-6265-48e5-89b8-8683b2e64a71';

  /// Initialisation complète
  static Future<void> init() async {
    // 1. Mode debug
    if (kDebugMode) {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    }

    // 2. Initialiser OneSignal
    OneSignal.initialize(_oneSignalAppId);

    // 3. Demander la permission
    await OneSignal.Notifications.requestPermission(true);

    // 4. Observer les changements de subscription
    OneSignal.User.pushSubscription.addObserver((state) {
      final playerId = state.current.id;
      debugPrint('🔔 OneSignal Player ID: $playerId');
      if (playerId != null) {
        _savePlayerIdIfSignedIn(playerId);
      }
    });

    // 5. Clic sur notification
    OneSignal.Notifications.addClickListener((event) {
      debugPrint('👆 Notification cliquée: ${event.notification.title}');
    });

    // 6. 🔥 Notif reçue au premier plan → sauvegarder dans Firestore
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint('📩 Notif reçue: ${event.notification.title}');

      // ✅ SAUVEGARDER DANS FIRESTORE
      _saveNotificationToFirestore(event.notification);

      // Afficher la notification système
      event.notification.display();
    });

    // 7. Sauvegarder le playerId si déjà connecté
    await _savePlayerIdIfSignedInFromCurrent();
  }

  /// 🔥 Sauvegarde une notification push dans Firestore
  static Future<void> _saveNotificationToFirestore(
      OSNotification notification) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⚠️ Utilisateur non connecté — notif non sauvegardée');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': notification.title ?? 'Notification',
        'body': notification.body ?? '',
        'type': notification.additionalData?['type'] ?? 'push',
        'isRead': false,
        'source': 'onesignal',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Notification sauvegardée dans Firestore');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde notif: $e');
    }
  }

  /// Sauvegarder le Player ID dans Firestore
  static Future<void> _savePlayerIdIfSignedIn(String playerId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'oneSignalPlayerId': playerId,
        'playerIdUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ Player ID sauvegardé');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde player ID: $e');
    }
  }

  static Future<void> _savePlayerIdIfSignedInFromCurrent() async {
    final playerId = OneSignal.User.pushSubscription.id;
    if (playerId != null) {
      await _savePlayerIdIfSignedIn(playerId);
    }
  }

  /// Appeler après login/register
  static Future<void> onUserSignedIn() async {
    final playerId = OneSignal.User.pushSubscription.id;
    if (playerId != null) {
      await _savePlayerIdIfSignedIn(playerId);
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await OneSignal.login(user.uid);
      debugPrint('✅ OneSignal associé à ${user.uid}');
    }
  }

  /// Nettoyer à la déconnexion
  static Future<void> onUserSignedOut() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'oneSignalPlayerId': FieldValue.delete()});
    }
    await OneSignal.logout();
    debugPrint('🚪 OneSignal déconnecté');
  }

  /// Récupérer le player ID
  static String? getPlayerId() => OneSignal.User.pushSubscription.id;
}
