import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/courier/courier_service.dart';
import '../../../domain/entities/courier.dart';
import '../../widgets/snackbars/app_snackbar.dart';

class CourierRegisterPage extends StatefulWidget {
  const CourierRegisterPage({super.key});

  @override
  State<CourierRegisterPage> createState() => _CourierRegisterPageState();
}

class _CourierRegisterPageState extends State<CourierRegisterPage> {
  final _pageController = PageController();

  // Étape actuelle
  int _step = 0;

  // Contrôleurs
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _idCardCtrl = TextEditingController();

  String _city = 'Abidjan';
  String _zone = 'Cocody';
  VehicleType _vehicleType = VehicleType.motorcycle;
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;
  bool _acceptCommission = false;
  bool _loading = false;

  // Zones d'Abidjan
  final _zones = [
    'Cocody',
    'Plateau',
    'Yopougon',
    'Adjamé',
    'Abobo',
    'Treichville',
    'Marcory',
    'Koumassi',
    'Port-Bouët',
    'Bingerville',
    'Riviera',
    'Angré',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _addressCtrl.dispose();
    _plateCtrl.dispose();
    _idCardCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 0) {
      // Validation étape 1
      if (_nameCtrl.text.isEmpty ||
          _phoneCtrl.text.length < 8 ||
          _emailCtrl.text.isEmpty ||
          _passCtrl.text.length < 6) {
        AppSnackbar.warning(context, 'Remplissez tous les champs correctement');
        return;
      }
    } else if (_step == 1) {
      // Validation étape 2 : adresse + plaque uniquement
      if (_addressCtrl.text.trim().isEmpty ||
          _plateCtrl.text.trim().isEmpty) {
        AppSnackbar.warning(context, 'Remplissez tous les champs');
        return;
      }
    }

    setState(() => _step++);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _register() async {
    // Vérifier le CNI (étape 3)
    if (_idCardCtrl.text.trim().isEmpty) {
      AppSnackbar.warning(context, 'Saisissez votre numéro de CNI');
      return;
    }

    if (!_acceptTerms || !_acceptPrivacy || !_acceptCommission) {
      AppSnackbar.warning(
          context, 'Acceptez toutes les conditions pour continuer');
      return;
    }

    setState(() => _loading = true);

    try {
      await CourierService.registerCourier(
        email: _emailCtrl.text,
        password: _passCtrl.text,
        fullName: _nameCtrl.text,
        phone: _phoneCtrl.text,
        city: _city,
        zone: _zone,
        address: _addressCtrl.text,
        vehicleType: _vehicleType,
        vehiclePlate: _plateCtrl.text,
        idCardNumber: _idCardCtrl.text,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle,
                color: AppColors.success, size: 48),
          ),
          title: const Text(
            'Inscription réussie !',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          content: const Text(
            'Votre dossier a été envoyé.\n\n'
            'Un administrateur vérifiera vos informations sous 24h.\n\n'
            'Vous recevrez une notification dès validation.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/courier/login');
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Compris',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Devenir livreur'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── INDICATEUR D'ÉTAPES ───
            _buildStepper(),

            // ─── CONTENU ───
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),

            // ─── BOUTONS ───
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // INDICATEUR D'ÉTAPES
  // ═══════════════════════════════════════
  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            _stepDot(i),
            if (i < 2)
              Expanded(
                child: Container(
                  height: 2,
                  color: _step > i
                      ? AppColors.success
                      : Colors.grey.shade300,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _stepDot(int index) {
    final isActive = index == _step;
    final isDone = index < _step;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.success
            : isActive
                ? AppColors.primary
                : Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isDone
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : Text(
                '${index + 1}',
                maxLines: 1,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // ÉTAPE 1 : Informations personnelles
  // ═══════════════════════════════════════
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Informations personnelles',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Vos coordonnées pour vous contacter',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),

          _field(_nameCtrl, 'Nom complet *', Icons.person_outline,
              capitalization: TextCapitalization.words),
          const SizedBox(height: 14),
          _field(_phoneCtrl, 'Téléphone *', Icons.phone_outlined,
              keyboard: TextInputType.phone, digitsOnly: true),
          const SizedBox(height: 14),
          _field(_emailCtrl, 'Email *', Icons.email_outlined,
              keyboard: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _field(_passCtrl, 'Mot de passe * (6 car. min)', Icons.lock_outline,
              obscure: true),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // ÉTAPE 2 : Véhicule et zone
  // ═══════════════════════════════════════
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Véhicule et zone',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Où et comment livrez-vous ?',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // ─── TYPE DE VÉHICULE ───
          const Text(
            'Type de véhicule *',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: VehicleType.values.map((type) {
              final selected = _vehicleType == type;
              return GestureDetector(
                onTap: () => setState(() => _vehicleType = type),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconForVehicle(type),
                        size: 18,
                        color: selected
                            ? AppColors.primary
                            : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        type.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.primary
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          _field(_plateCtrl, 'Plaque d\'immatriculation *',
              Icons.confirmation_number_outlined,
              capitalization: TextCapitalization.characters),

          const SizedBox(height: 20),

          // ─── VILLE ───
          const Text(
            'Ville *',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _city,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.location_city),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            items: const [
              DropdownMenuItem(value: 'Abidjan', child: Text('Abidjan')),
              DropdownMenuItem(value: 'Bouaké', child: Text('Bouaké')),
              DropdownMenuItem(value: 'Yamoussoukro', child: Text('Yamoussoukro')),
            ],
            onChanged: (v) => setState(() => _city = v ?? 'Abidjan'),
          ),

          const SizedBox(height: 20),

          // ─── ZONE ───
          const Text(
            'Zone préférée *',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _zone,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.map_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            items: _zones
                .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                .toList(),
            onChanged: (v) => setState(() => _zone = v ?? 'Cocody'),
          ),

          const SizedBox(height: 20),

          _field(_addressCtrl, 'Adresse complète *', Icons.location_on_outlined,
              maxLines: 2),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // ÉTAPE 3 : Vérification et conditions
  // ═══════════════════════════════════════
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Vérification et conditions',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Dernière étape avant validation',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // ─── CNI ───
          _field(_idCardCtrl, 'Numéro CNI *', Icons.badge_outlined,
              capitalization: TextCapitalization.characters),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Une photo de votre CNI sera demandée après validation',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── CONDITIONS ───
          const Text(
            'Conditions à accepter',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 12),

          _checkbox(
            value: _acceptTerms,
            title: 'Conditions générales',
            subtitle: 'J\'accepte les CGU de Flash Deals',
            onChanged: (v) => setState(() => _acceptTerms = v ?? false),
          ),
          _checkbox(
            value: _acceptPrivacy,
            title: 'Politique de confidentialité',
            subtitle: 'J\'accepte le traitement de mes données',
            onChanged: (v) => setState(() => _acceptPrivacy = v ?? false),
          ),
          _checkbox(
            value: _acceptCommission,
            title: 'Commission de 15%',
            subtitle:
                'J\'accepte que Flash Deals prélève 15% sur chaque livraison',
            onChanged: (v) => setState(() => _acceptCommission = v ?? false),
          ),

          const SizedBox(height: 24),

          // ─── RÉCAP ───
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📋 Récapitulatif',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                _recapRow('Nom', _nameCtrl.text),
                _recapRow('Téléphone', _phoneCtrl.text),
                _recapRow('Email', _emailCtrl.text),
                _recapRow('Véhicule', _vehicleType.label),
                _recapRow('Plaque', _plateCtrl.text),
                _recapRow('Zone', _zone),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recapRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value.isEmpty ? '—' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // BOTTOM BAR
  // ═══════════════════════════════════════
  Widget _buildBottomBar() {
    return Container(
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
        child: Row(
          children: [
            if (_step > 0) ...[
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _prevStep,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text(
                      'Retour',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _loading
                      ? null
                      : (_step == 2 ? _register : _nextStep),
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _step == 2 ? Icons.check : Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
                        ),
                  label: Text(
                    _loading
                        ? 'Envoi...'
                        : (_step == 2 ? 'Valider' : 'Suivant'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // CHAMPS
  // ═══════════════════════════════════════
  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    int maxLines = 1,
    bool obscure = false,
    bool digitsOnly = false,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: obscure ? 1 : maxLines,
      obscureText: obscure,
      textCapitalization: capitalization,
      inputFormatters: digitsOnly
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _checkbox({
    required bool value,
    required String title,
    required String subtitle,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: value
                ? AppColors.success.withOpacity(0.08)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value
                  ? AppColors.success
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.success,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForVehicle(VehicleType type) {
    switch (type) {
      case VehicleType.motorcycle:
        return Icons.two_wheeler;
      case VehicleType.bicycle:
        return Icons.pedal_bike;
      case VehicleType.car:
        return Icons.directions_car;
      case VehicleType.scooter:
        return Icons.motorcycle;
    }
  }
}
