import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/place_search_service.dart';
import 'place_search_bar.dart';

class MapPicker extends StatefulWidget {
  final LatLng? initialPosition;
  final ValueChanged<LatLng> onPositionChanged;
  final double? height;
  final bool showControls;
  final bool useCurrentLocationByDefault;

  const MapPicker({
    super.key,
    this.initialPosition,
    required this.onPositionChanged,
    this.height,
    this.showControls = true,
    this.useCurrentLocationByDefault = true,
  });

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  late LatLng _selected;
  final MapController _mapController = MapController();
  bool _mapReady = false;
  bool _isMoving = false;
  bool _loadingLocation = true;
  bool _loadingAddress = false;
  String? _currentAddress;

  /// Vrai si l'utilisateur a choisi lui-même un point sur la carte.
  /// Dans ce cas, le GPS ne doit pas écraser son choix.
  bool _userPicked = false;

  @override
  void initState() {
    super.initState();
    // Position de repli (Abidjan) en attendant le GPS
    _selected = widget.initialPosition ?? LocationService.defaultPosition;

    if (widget.initialPosition == null) {
      // Le parent reçoit tout de suite une position valide
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onPositionChanged(_selected);
      });
    }

    // Ma position = position sélectionnée par défaut
    if (widget.useCurrentLocationByDefault && widget.initialPosition == null) {
      _loadCurrentLocation();
    } else {
      _loadingLocation = false;
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation({bool force = false}) async {
    setState(() => _loadingLocation = true);

    final position = await LocationService.getCurrentPosition();

    if (!mounted) return;

    // L'utilisateur a déjà touché la carte pendant la recherche GPS :
    // on garde son choix (sauf si on force via le bouton « Ma position »).
    if (!force && _userPicked) {
      setState(() => _loadingLocation = false);
      return;
    }

    setState(() {
      _selected = position;
      _userPicked = false;
      _loadingLocation = false;
      _currentAddress = null;
    });

    widget.onPositionChanged(position);
    _loadAddress(position);

    if (_mapReady) {
      _mapController.move(position, 16);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    HapticFeedback.lightImpact();
    setState(() {
      _selected = point;
      _userPicked = true;
      _currentAddress = null;
    });
    widget.onPositionChanged(point);
    _loadAddress(point);
  }

  void _onMapReady() {
    setState(() => _mapReady = true);
    if (!_loadingLocation) {
      _mapController.move(_selected, 16);
    }
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture && !_isMoving) {
      setState(() => _isMoving = true);
    }
  }

  Future<void> _useCurrentLocation() async {
    HapticFeedback.mediumImpact();
    await _loadCurrentLocation(force: true);
  }

  /// Charge l'adresse à partir des coordonnées (reverse geocoding)
  Future<void> _loadAddress(LatLng position) async {
    setState(() => _loadingAddress = true);

    try {
      final address = await PlaceSearchService.reverseGeocode(position);
      if (!mounted) return;
      setState(() {
        _currentAddress = address;
        _loadingAddress = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingAddress = false);
    }
  }

  void _zoomIn() {
    final z = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (z + 1).clamp(3, 18));
  }

  void _zoomOut() {
    final z = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (z - 1).clamp(3, 18));
  }

  void _copyCoordinates() {
    final text = _currentAddress ??
        '${_selected.latitude.toStringAsFixed(6)}, ${_selected.longitude.toStringAsFixed(6)}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_currentAddress != null
            ? '📍 Adresse copiée'
            : '📍 Coordonnées copiées'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Une seule hauteur, tout est dessiné À L'INTÉRIEUR -> pas de débordement
        final mapHeight = widget.height ??
            (constraints.maxHeight.isFinite ? constraints.maxHeight : 340.0);

        return Container(
          height: mapHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned.fill(child: _buildMap()),

                // Chargement
                if (!_mapReady)
                  Positioned.fill(
                    child: Container(
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(strokeWidth: 2.5),
                            SizedBox(height: 12),
                            Text(
                              'Chargement de la carte...',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Bouton ma position
                if (widget.showControls && _mapReady)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _buildLocationButton(),
                  ),

                // Zoom
                if (widget.showControls && _mapReady)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _buildZoomControls(),
                  ),

                // Astuce (disparaît dès que l'utilisateur déplace la carte)
                if (_mapReady)
                  Positioned(
                    top: 12,
                    left: 64,
                    right: 64,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: (!_isMoving && !_loadingLocation) ? 1 : 0,
                        child: Center(child: _buildHint()),
                      ),
                    ),
                  ),

                // Barre de recherche (en haut)
                if (widget.showControls && _mapReady)
                  Positioned(
                    top: 12,
                    left: 64,
                    right: 64,
                    child: PlaceSearchBar(
                      nearPosition: _selected,
                      hintText: 'Rechercher un lieu...',
                      onPlaceSelected: (place) {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _selected = place.position;
                          _userPicked = true;
                          _currentAddress = place.displayName;
                        });
                        widget.onPositionChanged(place.position);
                        _mapController.move(place.position, 17);
                      },
                    ),
                  ),

                // Carte de coordonnées flottante
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _buildCoordinatesCard(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _selected,
        initialZoom: 16.0,
        minZoom: 3,
        maxZoom: 18,
        onTap: _onMapTap,
        onMapReady: _onMapReady,
        onPositionChanged: _onPositionChanged,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.flashdeals.ci.flash_deals_app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _selected,
              width: 56,
              height: 60,
              alignment: Alignment.topCenter,
              child: _buildMarker(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMarker() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(_selected), // ré-anime à chaque nouveau point
      tween: Tween(begin: 0.7, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.45),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 22),
          ),
          CustomPaint(
            size: const Size(12, 8),
            painter: _TrianglePainter(),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconButton(Icons.add, 'Zoom +', _zoomIn),
          Container(height: 1, width: 28, color: Colors.grey.shade200),
          _iconButton(Icons.remove, 'Zoom -', _zoomOut),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, color: Colors.black87, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.25),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _useCurrentLocation,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: _loadingLocation
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location,
                  color: AppColors.primary, size: 20),
        ),
      ),
    );
  }

  Widget _buildHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app, color: Colors.white, size: 14),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'Touchez pour placer le marqueur',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinatesCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _loadingLocation ? Icons.location_searching : Icons.check_circle,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loadingLocation
                      ? 'Recherche de votre position...'
                      : _loadingAddress
                          ? 'Chargement de l\'adresse...'
                          : 'Position sélectionnée',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                if (_loadingAddress)
                  const SizedBox(
                    height: 16,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.8),
                      ),
                    ),
                  )
                else if (_currentAddress != null && _currentAddress!.isNotEmpty)
                  Text(
                    _currentAddress!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  )
                else
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_selected.latitude.toStringAsFixed(4)}, '
                      '${_selected.longitude.toStringAsFixed(4)}',
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _copyCoordinates,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.copy, color: AppColors.primary, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
