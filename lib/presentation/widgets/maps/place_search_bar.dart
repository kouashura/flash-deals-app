import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/place_search_service.dart';

/// Barre de recherche de lieu avec suggestions en temps réel
class PlaceSearchBar extends StatefulWidget {
  final LatLng? nearPosition;
  final ValueChanged<PlaceResult> onPlaceSelected;
  final String hintText;

  const PlaceSearchBar({
    super.key,
    this.nearPosition,
    required this.onPlaceSelected,
    this.hintText = 'Rechercher un lieu...',
  });

  @override
  State<PlaceSearchBar> createState() => _PlaceSearchBarState();
}

class _PlaceSearchBarState extends State<PlaceSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  List<PlaceResult> _results = [];
  bool _loading = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _showResults = _focusNode.hasFocus && _results.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();

    if (query.trim().length < 3) {
      setState(() {
        _results = [];
        _loading = false;
        _showResults = false;
      });
      return;
    }

    setState(() => _loading = true);

    // Debounce : attendre 400ms avant de lancer la requête
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await PlaceSearchService.search(
        query,
        limit: 6,
        near: widget.nearPosition,
      );

      if (!mounted) return;

      setState(() {
        _results = results;
        _loading = false;
        _showResults = true;
      });
    });
  }

  void _onSelect(PlaceResult place) {
    _controller.text = place.shortName;
    _focusNode.unfocus();
    setState(() {
      _results = [];
      _showResults = false;
    });
    widget.onPlaceSelected(place);
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _results = [];
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ─── BARRE DE RECHERCHE ───
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.primary,
                  size: 22,
                ),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: _clear,
                          )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),

        // ─── RÉSULTATS ───
        if (_showResults && _results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _results.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                itemBuilder: (context, i) {
                  final place = _results[i];
                  return InkWell(
                    onTap: () => _onSelect(place),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _iconForType(place.type),
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  place.shortName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  place.displayName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

        // ─── AUCUN RÉSULTAT ───
        if (_showResults && _results.isEmpty && !_loading &&
            _controller.text.length >= 3)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.search_off, color: Colors.grey, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aucun lieu trouvé. Essayez un autre nom.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'house':
      case 'residential':
        return Icons.home;
      case 'road':
      case 'street':
        return Icons.directions;
      case 'shop':
      case 'supermarket':
      case 'mall':
        return Icons.store;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'restaurant':
      case 'cafe':
        return Icons.restaurant;
      case 'school':
      case 'university':
        return Icons.school;
      case 'hospital':
      case 'clinic':
        return Icons.local_hospital;
      case 'bank':
      case 'atm':
        return Icons.local_atm;
      default:
        return Icons.location_on;
    }
  }
}
