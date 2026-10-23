import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service d'envoi de notifications via OneSignal REST API V2
class AdminPushService {
  static const String _appId = 'c8659515-6265-48e5-89b8-8683b2e64a71';
  static const String _apiKey = String.fromEnvironment(
    'ONESIGNAL_RICH_API_KEY',
    defaultValue: '',
  );

  /// Envoi à tous les utilisateurs abonnés
  static Future<bool> sendToAll({
    required String title,
    required String body,
  }) async {
    try {
      debugPrint('═══════════════════════════════════════');
      debugPrint('🚀 ENVOI NOTIFICATION ONESIGNAL V2');
      debugPrint('   Titre: $title');
      debugPrint('   Body: $body');
      debugPrint('═══════════════════════════════════════');

      final response = await http.post(
        Uri.parse('https://api.onesignal.com/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Key $_apiKey',
        },
        body: jsonEncode({
          'app_id': _appId,
          'included_segments': ['All'],
          'headings': {'en': title, 'fr': title},
          'contents': {'en': body, 'fr': body},
          'target_channel': 'push',
        }),
      );

      debugPrint('📤 Status: ${response.statusCode}');
      debugPrint('📤 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Notification envoyée avec succès');
        return true;
      } else {
        debugPrint('❌ Erreur ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception: $e');
      return false;
    }
  }

  /// Envoi à un utilisateur spécifique via external_id
  static Future<bool> sendToUser({
    required String playerId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.onesignal.com/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Key $_apiKey',
        },
        body: jsonEncode({
          'app_id': _appId,
          'include_aliases': {
            'external_id': [playerId],
          },
          'target_channel': 'push',
          'headings': {'en': title, 'fr': title},
          'contents': {'en': body, 'fr': body},
          'data': data ?? {},
        }),
      );

      debugPrint('📤 User Status: ${response.statusCode}');
      debugPrint('📤 User Body: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ Exception: $e');
      return false;
    }
  }

  /// Envoi du statut d'une commande
  static Future<bool> sendOrderUpdate({
    required String orderId,
    required String userId,
    required String status,
  }) async {
    // Récupérer le player ID du client
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      debugPrint('❌ User $userId introuvable');
      return false;
    }

    final playerId = userDoc.data()?['oneSignalPlayerId'] as String?;
    if (playerId == null) {
      debugPrint('❌ Pas de player ID pour $userId');
      return false;
    }

    final messages = {
      'confirmed': {
        'title': '✅ Commande confirmée',
        'body': 'Votre commande a été confirmée.',
      },
      'preparing': {
        'title': '📦 En préparation',
        'body': 'Votre colis est en préparation.',
      },
      'onTheWay': {
        'title': '🚚 En cours de livraison',
        'body': 'Votre livreur est en route !',
      },
      'delivered': {
        'title': '🎉 Colis livré !',
        'body': 'Merci pour votre commande.',
      },
      'cancelled': {
        'title': '❌ Commande annulée',
        'body': 'Votre commande a été annulée.',
      },
    };

    final msg = messages[status];
    if (msg == null) return false;

    return sendToUser(
      playerId: playerId,
      title: msg['title']!,
      body: msg['body']!,
      data: {
        'type': 'order_update',
        'orderId': orderId,
        'status': status,
      },
    );
  }
}
