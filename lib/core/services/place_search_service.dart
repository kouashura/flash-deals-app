import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Résultat de recherche de lieu
class PlaceResult {
  final String displayName;
  final String shortName;
  final LatLng position;
  final String type;

  PlaceResult({
    required this.displayName,
    required this.shortName,
    required this.position,
    required this.type,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    final displayName = json['display_name'] as String? ?? '';
    final parts = displayName.split(',');
    final shortName = parts.isNotEmpty ? parts.first.trim() : displayName;

    return PlaceResult(
      displayName: displayName,
      shortName: shortName,
      position: LatLng(
        double.parse(json['lat'] as String),
        double.parse(json['lon'] as String),
      ),
      type: json['type'] as String? ?? 'place',
    );
  }
}

/// Service de recherche de lieux via Nominatim (OpenStreetMap)
/// 100% gratuit, pas de clé API
class PlaceSearchService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  /// Recherche des lieux par nom/adresse
  /// Retourne une liste de résultats triés par pertinence
  static Future<List<PlaceResult>> search(
    String query, {
    int limit = 5,
    LatLng? near,
  }) async {
    if (query.trim().length < 3) return [];

    try {
      // Construire l'URL
      final params = <String, String>{
        'q': query.trim(),
        'format': 'json',
        'addressdetails': '1',
        'limit': limit.toString(),
        'accept-language': 'fr',
        'countrycodes': 'ci', // Côte d'Ivoire uniquement (optionnel)
      };

      // Biais de proximité (résultats proches en priorité)
      if (near != null) {
        params['viewbox'] =
            '${near.longitude - 0.5},${near.latitude + 0.5},'
            '${near.longitude + 0.5},${near.latitude - 0.5}';
        params['bounded'] = '0';
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: params);

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'FlashDealsAbidjan/1.0 (contact@flashdeals.ci)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('❌ Nominatim error: ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((item) => PlaceResult.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur recherche lieu: $e');
      return [];
    }
  }

  /// Recherche inversée : coordonnées → adresse
  static Future<String?> reverseGeocode(LatLng position) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse',
      ).replace(queryParameters: {
        'lat': position.latitude.toString(),
        'lon': position.longitude.toString(),
        'format': 'json',
        'accept-language': 'fr',
      });

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'FlashDealsAbidjan/1.0 (contact@flashdeals.ci)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['display_name'] as String?;
    } catch (e) {
      debugPrint('❌ Erreur reverse geocode: $e');
      return null;
    }
  }
}
