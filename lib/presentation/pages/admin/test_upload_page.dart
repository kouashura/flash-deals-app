import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/image_upload_service.dart';
import '../../widgets/snackbars/app_snackbar.dart';

class TestUploadPage extends StatefulWidget {
  const TestUploadPage({super.key});

  @override
  State<TestUploadPage> createState() => _TestUploadPageState();
}

class _TestUploadPageState extends State<TestUploadPage> {
  final _service = ImageUploadService();
  String? _imageUrl;
  bool _loading = false;

  Future<void> _upload() async {
    setState(() => _loading = true);
    final url = await _service.pickAndUpload();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _imageUrl = url;
    });

    if (url == null && mounted) {
      AppSnackbar.error(context, '❌ Upload échoué');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Test upload image')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_imageUrl != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.network(
                  _imageUrl!,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    size: 80,
                    color: Colors.grey,
                  ),
                  loadingBuilder: (_, child, progress) =>
                      progress == null
                          ? child
                          : const Center(
                              child: CircularProgressIndicator(),
                            ),
                ),
              ),
            const SizedBox(height: 16),
            if (_imageUrl != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _imageUrl!,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _upload,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload, color: Colors.white),
                label: Text(
                  _loading ? 'Upload en cours...' : 'Choisir une image',
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
          ],
        ),
      ),
    );
  }
}
