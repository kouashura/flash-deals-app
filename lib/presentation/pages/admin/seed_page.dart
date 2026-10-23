import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/seed_service.dart';

class SeedPage extends StatefulWidget {
  const SeedPage({super.key});

  @override
  State<SeedPage> createState() => _SeedPageState();
}

class _SeedPageState extends State<SeedPage> {
  final _service = SeedService();
  final List<String> _logs = [];
  bool _loading = false;

  void _addLog(String log) => setState(() => _logs.add(log));

  Future<void> _runSeed() async {
    setState(() {
      _loading = true;
      _logs.clear();
    });

    _addLog('🌱 Démarrage...');

    try {
      await _service.seedAll();
      _addLog('');
      _addLog('✅ SEED TERMINÉ !');
      _addLog('Vérifiez la console Firebase.');
    } catch (e) {
      _addLog('');
      _addLog('❌ ERREUR : $e');
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tout supprimer ?'),
        content: const Text(
          'Collections products, categories, stores et notifications '
          'seront vidées. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _loading = true;
      _logs.clear();
    });

    _addLog('🗑️ Suppression en cours...');

    try {
      await _service.clearAll();
      _addLog('');
      _addLog('✅ Collections vidées');
    } catch (e) {
      _addLog('❌ Erreur : $e');
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Initialisation Firestore')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '⚠️ À exécuter UNE SEULE FOIS. '
                      'Crée : products, categories, stores, notifications, users.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _runSeed,
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload,
                              color: Colors.white),
                      label: Text(
                        _loading ? 'En cours...' : 'Lancer le seed',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 52,
                  width: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _clearAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.delete_sweep, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B1F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _logs.isEmpty
                        ? [
                            const Text(
                              'En attente...',
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ]
                        : _logs
                            .map((log) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 2),
                                  child: SelectableText(
                                    log,
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                ))
                            .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
