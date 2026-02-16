// ===============================
// FILE NAME: stories_service.dart
// FILE PATH: lib/services/stories_service.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

const String cloudinaryCloudName = "dcboqibnx";
const String cloudinaryUploadPreset = "flutter_profile_uploads";

class Story {
  final String id;
  final String userId;
  final String userName;
  final String userImage;
  final String imageUrl;
  final Timestamp timestamp;
  final List<dynamic> viewers;

  Story({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.imageUrl,
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
      timestamp: data['timestamp'] ?? Timestamp.now(),
      viewers: data['viewers'] ?? [],
    );
  }
}

class StoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload a new story
  Future<void> uploadStory(XFile imageFile) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // 1. Get User Details
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data()!;

      // 2. Upload Image
      final cloudinary = CloudinaryPublic(
        cloudinaryCloudName,
        cloudinaryUploadPreset,
      );
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile.path, folder: "stories"),
      );

      // 3. Save to Firestore
      await _firestore.collection('stories').add({
        'userId': user.uid,
        'userName': userData['displayName'] ?? 'User',
        'userImage': userData['profilePhotoUrl'] ?? '',
        'imageUrl': response.secureUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'viewers': [],
      });
    } catch (e) {
      throw Exception("Failed to upload story: $e");
    }
  }

  // Get stories from last 24 hours
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

  // Mark story as viewed
  Future<void> viewStory(String storyId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('stories').doc(storyId).update({
      'viewers': FieldValue.arrayUnion([user.uid]),
    });
  }

  // Delete a story
  Future<void> deleteStory(String storyId) async {
    try {
      await _firestore.collection('stories').doc(storyId).delete();
    } catch (e) {
      throw Exception("Failed to delete story: $e");
    }
  }
}
