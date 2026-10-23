import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/distance_service.dart';

/// Carte affichant :
/// - 🏪 Le magasin (point de départ)
/// - 📍 Le client (destination)
/// - 🚚 Le livreur (position simulée)
/// - Une ligne entre magasin et client
class DeliveryMap extends StatefulWidget {
  final LatLng storePosition;
  final LatLng clientPosition;
  final String storeName;
  final String status;
  final double height;

  const DeliveryMap({
    super.key,
    required this.storePosition,
    required this.clientPosition,
    required this.storeName,
    required this.status,
    this.height = 280,
  });

  @override
  State<DeliveryMap> createState() => _DeliveryMapState();
}

class _DeliveryMapState extends State<DeliveryMap> {
  final MapController _mapController = MapController();

  LatLng get _courierPosition {
    double progress = 0.0;
    switch (widget.status) {
      case 'confirmed':
      case 'preparing':
        progress = 0.0;
        break;
      case 'onTheWay':
        progress = 0.5;
        break;
      case 'delivered':
        progress = 1.0;
        break;
      default:
        progress = 0.0;
    }

    final lat = widget.storePosition.latitude +
        (widget.clientPosition.latitude - widget.storePosition.latitude) *
            progress;
    final lng = widget.storePosition.longitude +
        (widget.clientPosition.longitude - widget.storePosition.longitude) *
            progress;
    return LatLng(lat, lng);
  }

  LatLng get _center {
    final lat =
        (widget.storePosition.latitude + widget.clientPosition.latitude) / 2;
    final lng =
        (widget.storePosition.longitude + widget.clientPosition.longitude) / 2;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    final showCourier = widget.status == 'onTheWay' ||
        widget.status == 'delivered' ||
        widget.status == 'preparing';

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // ─── CARTE ───
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 13.0,
                  minZoom: 8,
                  maxZoom: 18,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName:
                        'com.flashdeals.ci.flash_deals_app',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [
                          widget.storePosition,
                          widget.clientPosition,
                        ],
                        strokeWidth: 3,
                        color: AppColors.primary.withOpacity(0.6),
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      // 🏪 Magasin
                      Marker(
                        point: widget.storePosition,
                        width: 50,
                        height: 50,
                        alignment: Alignment.topCenter,
                        child: _buildMarker(
                          Icons.store,
                          Colors.teal,
                          'Magasin',
                        ),
                      ),
                      // 🚚 Livreur
                      if (showCourier)
                        Marker(
                          point: _courierPosition,
                          width: 50,
                          height: 50,
                          alignment: Alignment.topCenter,
                          child: _buildMarker(
                            Icons.delivery_dining,
                            Colors.blue,
                            'Livreur',
                            pulse: widget.status == 'onTheWay',
                          ),
                        ),
                      // 📍 Client
                      Marker(
                        point: widget.clientPosition,
                        width: 50,
                        height: 50,
                        alignment: Alignment.topCenter,
                        child: _buildMarker(
                          Icons.location_on,
                          AppColors.primary,
                          'Vous',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── BADGE DISTANCE (en haut, compact) ───
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Center(child: _buildDistanceBadge()),
            ),

            // ─── BOUTON RECENTRER (en bas à droite) ───
            Positioned(
              bottom: 8,
              right: 8,
              child: _buildRecenterButton(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── MARQUEUR ───
  Widget _buildMarker(IconData icon, Color color, String label,
      {bool pulse = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1.0),
          duration: pulse
              ? const Duration(milliseconds: 800)
              : const Duration(milliseconds: 300),
          curve: pulse ? Curves.easeInOut : Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: pulse ? 12 : 6,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
            );
          },
        ),
        const SizedBox(height: 2),
        // Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ─── BADGE DISTANCE (compact) ───
  Widget _buildDistanceBadge() {
    final distance = DistanceService.calculateKm(
      widget.storePosition,
      widget.clientPosition,
    );
    final time = DistanceService.estimatedTime(
      widget.storePosition,
      widget.clientPosition,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.route, color: AppColors.primary, size: 14),
          const SizedBox(width: 4),
          Text(
            '${distance.toStringAsFixed(1)} km',
            maxLines: 1,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 1,
            height: 10,
            color: Colors.grey.shade300,
          ),
          const Icon(Icons.access_time, color: Colors.grey, size: 12),
          const SizedBox(width: 3),
          Text(
            time,
            maxLines: 1,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOUTON RECENTRER (compact) ───
  Widget _buildRecenterButton() {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds.fromPoints([
                widget.storePosition,
                widget.clientPosition,
              ]),
              padding: const EdgeInsets.all(50),
            ),
          );
        },
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.center_focus_strong,
            color: AppColors.primary,
            size: 18,
          ),
        ),
      ),
    );
  }
}
