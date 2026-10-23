import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/flash_deals_service.dart';
import '../../widgets/snackbars/app_snackbar.dart';

class AdminFlashDealsPage extends StatefulWidget {
  const AdminFlashDealsPage({super.key});

  @override
  State<AdminFlashDealsPage> createState() => _AdminFlashDealsPageState();
}

class _AdminFlashDealsPageState extends State<AdminFlashDealsPage> {
  final _service = FlashDealsService();
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();

  DateTime? _endTime;
  bool _isActive = true;
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    super.dispose();
  }

  void _initFromConfig(FlashDealsConfig config) {
    if (_initialized) return;
    _titleCtrl.text = config.title;
    _subtitleCtrl.text = config.subtitle;
    _endTime = config.endTime;
    _isActive = config.isActive;
    _initialized = true;
  }

  Future<void> _save() async {
    setState(() => _loading = true);

    try {
      final config = FlashDealsConfig(
        title: _titleCtrl.text.trim().isEmpty
            ? 'VENTE FLASH'
            : _titleCtrl.text.trim(),
        subtitle: _subtitleCtrl.text.trim().isEmpty
            ? 'Se termine dans'
            : _subtitleCtrl.text.trim(),
        endTime: _endTime ?? DateTime.now().add(const Duration(hours: 5)),
        isActive: _isActive,
      );

      await _service.updateConfig(config);

      if (!mounted) return;
      AppSnackbar.success(context, 'Bannière mise à jour');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: _endTime ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endTime ?? now),
    );

    if (time == null) return;

    setState(() {
      _endTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _setQuickDuration(Duration d) {
    setState(() {
      _endTime = DateTime.now().add(d);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Bannière Vente Flash')),
      body: StreamBuilder<FlashDealsConfig>(
        stream: _service.streamConfig(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _initFromConfig(snapshot.data!);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // === APERÇU ===
              _sectionTitle('Aperçu'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFFFF9800)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flash_on,
                        color: Colors.white, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titleCtrl.text.isEmpty
                                ? 'VENTE FLASH'
                                : _titleCtrl.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            _subtitleCtrl.text.isEmpty
                                ? 'Se termine dans'
                                : _subtitleCtrl.text,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // === ACTIVER/DÉSACTIVER ===
              _sectionTitle('État'),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: const Text('Bannière active',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    _isActive
                        ? 'Visible sur la Home'
                        : 'Cachée sur la Home',
                    style: const TextStyle(fontSize: 12),
                  ),
                  activeColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),

              // === TITRE ===
              _sectionTitle('Titre'),
              TextField(
                controller: _titleCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Ex: VENTE FLASH',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // === SOUS-TITRE ===
              _sectionTitle('Sous-titre'),
              TextField(
                controller: _subtitleCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Ex: Se termine dans',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // === DATE DE FIN ===
              _sectionTitle('Date de fin'),
              InkWell(
                onTap: _pickDateTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _endTime == null
                              ? 'Choisir une date'
                              : _formatDateTime(_endTime!),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // === DURÉES RAPIDES ===
              _sectionTitle('Durées rapides'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _quickBtn('1 heure', const Duration(hours: 1)),
                  _quickBtn('6 heures', const Duration(hours: 6)),
                  _quickBtn('12 heures', const Duration(hours: 12)),
                  _quickBtn('24 heures', const Duration(hours: 24)),
                  _quickBtn('3 jours', const Duration(days: 3)),
                  _quickBtn('1 semaine', const Duration(days: 7)),
                ],
              ),
              const SizedBox(height: 32),

              // === BOUTON ENREGISTRER ===
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _save,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, color: Colors.white),
                  label: Text(
                    _loading ? 'Enregistrement...' : 'Enregistrer',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _quickBtn(String label, Duration duration) {
    return ActionChip(
      label: Text(label),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      onPressed: () => _setQuickDuration(duration),
    );
  }

  String _formatDateTime(DateTime d) {
    return '${d.day}/${d.month}/${d.year} à '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}
