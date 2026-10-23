import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Service d'upload d'images vers Cloudinary.
/// Configuration via upload preset non signé (pas de clé API exposée).
class ImageUploadService {
  // ⚙️ REMPLACEZ CES VALEURS PAR LES VÔTRES
  static const String _cloudName = 'dsb5k6y4o';
  static const String _uploadPreset = 'flash_deals_preset';

  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  final ImagePicker _picker = ImagePicker();

  /// Sélectionne une image depuis la galerie
  Future<XFile?> pickImage({bool fromCamera = false}) async {
    return await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
  }

  /// Upload un fichier vers Cloudinary et retourne l'URL sécurisée
  Future<String?> uploadImage(XFile file) async {
    try {
      final uri = Uri.parse(_uploadUrl);
      final request = http.MultipartRequest('POST', uri);

      // Champs obligatoires
      request.fields['upload_preset'] = _uploadPreset;

      // Ajouter le fichier (Web compatible)
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: file.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('file', file.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['secure_url'] as String?;
      } else {
        debugPrint('Cloudinary error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  /// Sélectionne + upload en une seule méthode
  Future<String?> pickAndUpload({bool fromCamera = false}) async {
    final file = await pickImage(fromCamera: fromCamera);
    if (file == null) return null;
    return uploadImage(file);
  }
}
