// ===============================
// FILE PATH: lib/features/posts/providers/feed_provider.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the currently logged-in Firebase User
final currentUserProvider = Provider<User?>((ref) {
  return FirebaseAuth.instance.currentUser;
});

/// Streams the current user's Firestore document.
/// We need this to get the user's `connections` list to filter private posts.
final userDataProvider = StreamProvider<DocumentSnapshot?>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots();
});

/// Streams all posts from Firestore, ordered by newest first.
/// By placing this in a Riverpod StreamProvider, Flutter caches the stream
/// and prevents the UI from rebuilding the entire list unnecessarily.
final postsFeedProvider = StreamProvider<List<DocumentSnapshot>>((ref) {
  return FirebaseFirestore.instance
      .collection('posts')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs);
});
