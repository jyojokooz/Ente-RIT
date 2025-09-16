import 'dart:convert';
import 'package:flutter/foundation.dart'; // <-- IMPORT ADDED
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String _cloudinaryCloudName = "dcboqibnx";
  static const String _cloudinaryUploadPreset = "flutter_profile_uploads";
  static const String _uploadUrl =
      "https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload";

  static Future<String?> uploadImage(XFile imageFile) async {
    try {
      final uri = Uri.parse(_uploadUrl);
      final request =
          http.MultipartRequest('POST', uri)
            ..fields['upload_preset'] = _cloudinaryUploadPreset
            ..files.add(
              await http.MultipartFile.fromPath('file', imageFile.path),
            );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final decodedData = json.decode(responseData);
        return decodedData['secure_url'];
      } else {
        // --- 'print' REPLACED WITH 'debugPrint' ---
        debugPrint(
          'Cloudinary upload failed with status: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      // --- 'print' REPLACED WITH 'debugPrint' ---
      debugPrint('Error uploading to Cloudinary: $e');
      return null;
    }
  }
}
