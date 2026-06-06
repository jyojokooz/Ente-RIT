import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches and caches a user's profile document based on their userId
final userProfileProvider = StreamProvider.family<DocumentSnapshot, String>((
  ref,
  userId,
) {
  return FirebaseFirestore.instance.collection('users').doc(userId).snapshots();
});

/// Fetches and caches posts created by a specific user
final userPostsProvider = StreamProvider.family<List<DocumentSnapshot>, String>(
  (ref, userId) {
    return FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final docs = snap.docs.toList();
          docs.sort((a, b) {
            // FIX: Removed the unnecessary "as Map<String, dynamic>" casts
            final dataA = a.data();
            final dataB = b.data();

            final tA = dataA['timestamp'] as Timestamp?;
            final tB = dataB['timestamp'] as Timestamp?;

            if (tA == null && tB == null) return 0;
            if (tA == null) return 1;
            if (tB == null) return -1;
            return tB.compareTo(tA); // Descending order
          });
          return docs;
        });
  },
);

/// Fetches and caches posts where a specific username is tagged
final userTaggedPostsProvider =
    StreamProvider.family<List<DocumentSnapshot>, String>((ref, username) {
      return FirebaseFirestore.instance
          .collection('posts')
          .where('taggedUsers', arrayContains: username)
          .snapshots()
          .map((snap) {
            final docs = snap.docs.toList();
            docs.sort((a, b) {
              // FIX: Removed the unnecessary "as Map<String, dynamic>" casts
              final dataA = a.data();
              final dataB = b.data();

              final tA = dataA['timestamp'] as Timestamp?;
              final tB = dataB['timestamp'] as Timestamp?;

              if (tA == null && tB == null) return 0;
              if (tA == null) return 1;
              if (tB == null) return -1;
              return tB.compareTo(tA); // Descending order
            });
            return docs;
          });
    });

/// Fetches and caches the top 50 recent posts for the Explore page
final trendingPostsProvider = StreamProvider<List<DocumentSnapshot>>((ref) {
  return FirebaseFirestore.instance
      .collection('posts')
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs);
});
