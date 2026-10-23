import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../widgets/maps/map_picker.dart';
import '../../widgets/snackbars/app_snackbar.dart';

class AddressInputPage extends StatefulWidget {
  final String? initialAddress;
  final LatLng? initialPosition;

  const AddressInputPage({
    super.key,
    this.initialAddress,
    this.initialPosition,
  });

  @override
  State<AddressInputPage> createState() => _AddressInputPageState();
}

class _AddressInputPageState extends State<AddressInputPage> {
  final _labelCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  LatLng _position = LocationService.defaultPosition;
  String? _mapAddress;
  String _mode = 'map'; // 'map' | 'text'

  @override
  void initState() {
    super.initState();

    if (widget.initialAddress != null) {
      _detailsCtrl.text = widget.initialAddress!;
    }
    if (widget.initialPosition != null) {
      _position = widget.initialPosition!;
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _detailsCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _validate() {
    // Téléphone obligatoire
    if (_phoneCtrl.text.length < 8) {
      AppSnackbar.warning(
          context, 'Veuillez saisir un numéro de téléphone valide');
      return;
    }

    // Construire l'adresse finale
    String finalAddress;
    if (_mode == 'text') {
      if (_detailsCtrl.text.trim().isEmpty) {
        AppSnackbar.warning(context, 'Veuillez saisir votre adresse');
        return;
      }
      finalAddress = _detailsCtrl.text.trim();
    } else {
      // Mode carte : préférer l'adresse du reverse geocoding
      if (_mapAddress != null && _mapAddress!.isNotEmpty) {
        finalAddress = _mapAddress!;
      } else {
        finalAddress =
            '${_position.latitude.toStringAsFixed(4)}, ${_position.longitude.toStringAsFixed(4)}';
      }

      // Ajouter les détails si renseignés
      if (_detailsCtrl.text.trim().isNotEmpty) {
        finalAddress = '$finalAddress • ${_detailsCtrl.text.trim()}';
      }
    }

    Navigator.pop(context, {
      'address': finalAddress,
      'label': _labelCtrl.text.trim().isEmpty
          ? 'Adresse'
          : _labelCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'latitude': _position.latitude,
      'longitude': _position.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Adresse de livraison'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ═══ SÉLECTEUR DE MODE ═══
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildModeSelector(),
            ),

            // ═══ CONTENU SCROLLABLE ═══
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── TÉLÉPHONE ───
                    const Text(
                      '📞 Numéro de téléphone *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '+225 07 XX XX XX XX',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.phone),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── LABEL ───
                    const Text(
                      '🏷️ Nom de l\'adresse',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _labelCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Ex : Domicile, Bureau...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.label_outline),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── ADRESSE ───
                    if (_mode == 'map') ...[
                      const Text(
                        '📍 Position sur la carte *',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 420,
                        child: MapPicker(
                          initialPosition: widget.initialPosition,
                          onPositionChanged: (position) {
                            setState(() => _position = position);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        '📝 Détails supplémentaires',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _detailsCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Ex : Immeuble bleu, 2ème étage\nRéférence : à côté de la pharmacie',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ] else ...[
                      const Text(
                        '📍 Votre adresse complète *',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _detailsCtrl,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText:
                              'Ex : Cocody, pharmacie Mai\nAngré 7ème tranche, immeuble bleu...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 70),
                            child: Icon(Icons.location_on),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // ─── INFO ───
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Soyez précis (repère, pharmacie, école...) pour que le livreur vous trouve facilement.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ═══ BOUTON VALIDER ═══
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _validate,
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      'Valider l\'adresse',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _modeBtn('map', Icons.map_outlined, 'Sur la carte'),
          ),
          Expanded(
            child: _modeBtn(
                'text', Icons.edit_location_alt_outlined, 'Saisir à la main'),
          ),
        ],
      ),
    );
  }

  Widget _modeBtn(String mode, IconData icon, String label) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.primary : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.primary : Colors.grey.shade600,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
