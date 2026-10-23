import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Service de localisation GPS
class LocationService {
  static const LatLng _defaultAbidjan = LatLng(5.359952, -4.008256);

  /// Récupère la position actuelle de l'utilisateur
  /// Retourne Abidjan si refus ou erreur
  static Future<LatLng> getCurrentPosition() async {
    try {
      // 1. Vérifier si le GPS est activé
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ GPS désactivé');
        return _defaultAbidjan;
      }

      // 2. Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Permission refusée');
          return _defaultAbidjan;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Permission refusée définitivement');
        return _defaultAbidjan;
      }

      // 3. Récupérer la position (nouvelle API)
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      debugPrint('✅ Position GPS: ${position.latitude}, ${position.longitude}');
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('❌ Erreur GPS: $e');
      return _defaultAbidjan;
    }
  }

  /// Retourne la position par défaut (Abidjan)
  static LatLng get defaultPosition => _defaultAbidjan;
}
