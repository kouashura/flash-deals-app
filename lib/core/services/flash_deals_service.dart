import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Configuration de la bannière Flash Deals
class FlashDealsConfig {
  final String title;
  final String subtitle;
  final DateTime endTime;
  final bool isActive;

  const FlashDealsConfig({
    required this.title,
    required this.subtitle,
    required this.endTime,
    required this.isActive,
  });

  /// Valeurs par défaut
  factory FlashDealsConfig.defaultConfig() {
    return FlashDealsConfig(
      title: 'VENTE FLASH',
      subtitle: 'Se termine dans',
      endTime: DateTime.now().add(const Duration(hours: 5)),
      isActive: true,
    );
  }

  factory FlashDealsConfig.fromMap(Map<String, dynamic> data) {
    return FlashDealsConfig(
      title: data['title'] as String? ?? 'VENTE FLASH',
      subtitle: data['subtitle'] as String? ?? 'Se termine dans',
      endTime: data['endTime'] is Timestamp
          ? (data['endTime'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(hours: 5)),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'endTime': Timestamp.fromDate(endTime),
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  FlashDealsConfig copyWith({
    String? title,
    String? subtitle,
    DateTime? endTime,
    bool? isActive,
  }) {
    return FlashDealsConfig(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
    );
  }
}

class FlashDealsService {
  final _db = FirebaseFirestore.instance;

  DocumentReference get _configDoc =>
      _db.collection('config').doc('flash_deals');

  /// Stream de la configuration en temps réel
  Stream<FlashDealsConfig> streamConfig() {
    return _configDoc.snapshots().map((snap) {
      if (!snap.exists) {
        return FlashDealsConfig.defaultConfig();
      }
      return FlashDealsConfig.fromMap(snap.data() as Map<String, dynamic>);
    });
  }

  /// Récupère la config actuelle
  Future<FlashDealsConfig> getConfig() async {
    final snap = await _configDoc.get();
    if (!snap.exists) {
      // Crée la config par défaut si elle n'existe pas
      final defaultConfig = FlashDealsConfig.defaultConfig();
      await _configDoc.set(defaultConfig.toMap());
      return defaultConfig;
    }
    return FlashDealsConfig.fromMap(snap.data() as Map<String, dynamic>);
  }

  /// Met à jour la configuration
  Future<void> updateConfig(FlashDealsConfig config) async {
    try {
      await _configDoc.set(config.toMap(), SetOptions(merge: true));
      debugPrint('✅ Config Flash Deals mise à jour');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour config: $e');
      rethrow;
    }
  }

  /// Active/désactive la bannière
  Future<void> toggleActive(bool isActive) async {
    await _configDoc.set(
      {'isActive': isActive, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  /// Change la date de fin
  Future<void> setEndTime(DateTime endTime) async {
    await _configDoc.set(
      {
        'endTime': Timestamp.fromDate(endTime),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Change le titre
  Future<void> setTitle(String title) async {
    await _configDoc.set(
      {'title': title, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  /// Change le sous-titre
  Future<void> setSubtitle(String subtitle) async {
    await _configDoc.set(
      {'subtitle': subtitle, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }
}
