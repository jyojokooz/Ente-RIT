import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class ImageUploadService {
  Future<String> uploadImage(File imageFile) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(imageFile.path)}';
      final ref = FirebaseStorage.instance
          .ref()
          .child('card_backgrounds')
          .child(fileName);
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
