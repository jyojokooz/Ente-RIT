import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class CloudinaryService {
  static Future<String?> uploadImage(XFile imageFile) async {
    try {
      final file = File(imageFile.path);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
      final ref = FirebaseStorage.instance
          .ref()
          .child('cafeteria_menu')
          .child(fileName);
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading to Firebase Storage: $e');
      return null;
    }
  }
}
