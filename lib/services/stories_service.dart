import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

const String cloudinaryCloudName = "dcboqibnx";
const String cloudinaryUploadPreset = "flutter_profile_uploads";

class Story {
  final String id;
  final String userId;
  final String userName;
  final String userImage;
  final String imageUrl;
  final String type;
  final Timestamp timestamp;
  final List<dynamic> viewers;

  Story({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.imageUrl,
    this.type = 'image',
    required this.timestamp,
    required this.viewers,
  });

  factory Story.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Story(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'User',
      userImage: data['userImage'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      type: data['type'] ?? 'image',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      viewers: data['viewers'] ?? [],
    );
  }
}

class StoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<File?> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(
      tempDir.path,
      '${DateTime.now().millisecondsSinceEpoch}_${file.hashCode}.jpg',
    );
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      minWidth: 1080,
      minHeight: 1920,
      quality: 80,
    );
    return result == null ? null : File(result.path);
  }

  // Upload multiple stories at once
  Future<void> uploadStories(List<File> imageFiles) async {
    final user = _auth.currentUser;
    if (user == null || imageFiles.isEmpty) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data()!;
      final cloudinary = CloudinaryPublic(
        cloudinaryCloudName,
        cloudinaryUploadPreset,
      );

      final batch = _firestore.batch();

      for (var file in imageFiles) {
        final compressedFile = await _compressImage(file) ?? file;

        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            compressedFile.path,
            folder: "stories/${user.uid}",
          ),
        );

        final docRef = _firestore.collection('stories').doc();
        batch.set(docRef, {
          'userId': user.uid,
          'userName': userData['displayName'] ?? 'User',
          'userImage': userData['profilePhotoUrl'] ?? '',
          'imageUrl': response.secureUrl,
          'type': 'image',
          'timestamp': FieldValue.serverTimestamp(),
          'viewers': [],
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception("Failed to upload stories: $e");
    }
  }

  Stream<List<Story>> getActiveStories() {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));
    final timestamp = Timestamp.fromDate(yesterday);

    return _firestore
        .collection('stories')
        .where('timestamp', isGreaterThan: timestamp)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Story.fromSnapshot(doc)).toList(),
        );
  }

  Future<void> viewStory(String storyId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('stories').doc(storyId).update({
      'viewers': FieldValue.arrayUnion([user.uid]),
    });
  }

  Future<void> deleteStory(String storyId) async {
    await _firestore.collection('stories').doc(storyId).delete();
  }
}
