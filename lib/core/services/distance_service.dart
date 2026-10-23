import 'package:latlong2/latlong.dart';

class DistanceService {
  static const Distance _distance = Distance();

  /// Calcule la distance entre 2 points en km
  static double calculateKm(LatLng from, LatLng to) {
    return _distance.as(LengthUnit.Kilometer, from, to);
  }

  /// Retourne un texte lisible : "1.2 km" ou "850 m"
  static String format(LatLng from, LatLng to) {
    final km = calculateKm(from, to);
    if (km < 1) {
      return '${(km * 1000).toStringAsFixed(0)} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  /// Estime le temps de livraison (vitesse moyenne 25 km/h)
  static String estimatedTime(LatLng from, LatLng to) {
    final km = calculateKm(from, to);
    final minutes = ((km / 25) * 60).round() + 10;
    if (minutes < 60) return '$minutes min';
    return '${(minutes / 60).toStringAsFixed(1)} h';
  }
}
