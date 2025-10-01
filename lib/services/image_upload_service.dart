// lib/services/image_upload_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ImageUploadService {
  final String? _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
  final String? _uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];

  /// Uploads the given image file to Cloudinary and returns the secure URL.
  /// Throws an exception if the upload fails or credentials are missing.
  Future<String> uploadImage(File imageFile) async {
    if (_cloudName == null || _uploadPreset == null) {
      throw Exception('Cloudinary credentials are not set in the .env file.');
    }

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    // --- FIX: Removed the unnecessary '!' operator ---
    final request =
        http.MultipartRequest('POST', url)
          ..fields['upload_preset'] = _uploadPreset
          ..files.add(
            await http.MultipartFile.fromPath('file', imageFile.path),
          );
    // --- END OF FIX ---

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final responseJson = json.decode(responseData);
        return responseJson['secure_url'];
      } else {
        final errorData = await response.stream.bytesToString();
        throw Exception(
          'Cloudinary upload failed: ${response.statusCode} - $errorData',
        );
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
