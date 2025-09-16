import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../comments_screen.dart';
import '../edit_post_screen.dart';
import '../post_card.dart';
import '../post_card_placeholder.dart';
import 'profile_screen.dart';
import '../chat_list_screen.dart';
import '../notifications_screen.dart'; // <-- IMPORT THE NEW SCREEN

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser!;

  Future<void> _refreshPosts() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _editPost(String postId, String currentCaption) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                EditPostScreen(postId: postId, initialCaption: currentCaption),
      ),
    );
  }

  // --- MODIFIED to accept postAuthorId to create notifications ---
  Future<void> _toggleLike(
    String postId,
    List<dynamic> currentLikes,
    String postAuthorId,
  ) async {
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    final isLiked = currentLikes.contains(user.uid);
    if (isLiked) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([user.uid]),
      });

      // --- NEW: LOGIC TO CREATE NOTIFICATION ---
      // Only create a notification if someone else likes the post (not the author themselves)
      if (postAuthorId != user.uid) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': postAuthorId, // The ID of the user to be notified
          'title': 'New Like',
          'body': '${user.displayName ?? 'Someone'} liked your post.',
          'type': 'like', // Helps in displaying the right icon
          'relatedDocId': postId, // To navigate to the post later if needed
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  void _onCommentTapped(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CommentsScreen(postId: postId)),
    );
  }

  void _onProfileTapped(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen(userId: userId)),
    );
  }

  Future<void> _deletePost(String postId) async {
    // ... (delete logic is unchanged)
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final bool? didRequestDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text('Delete Post?'),
          content: const Text(
            'Are you sure you want to permanently delete this post?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (didRequestDelete == true) {
      try {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .delete();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (scaffoldMessenger.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Failed to delete post: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryAccentColor = Colors.yellow;
    final Color cardBackgroundColor = Colors.grey.shade900;

    return RefreshIndicator(
      onRefresh: _refreshPosts,
      color: primaryAccentColor,
      backgroundColor: cardBackgroundColor,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildTopBar(Colors.white, cardBackgroundColor),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('posts')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const PostCardPlaceholder(),
                      childCount: 5,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Something went wrong!',
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No posts yet. Be the first!',
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                    ),
                  );
                }

                final posts = snapshot.data!.docs;
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final postSnapshot = posts[index];
                    final postData =
                        postSnapshot.data() as Map<String, dynamic>;
                    final postAuthorId = postData['userId'] ?? '';
                    final currentLikes = postData['likes'] ?? [];
                    final currentCaption = postData['caption'] ?? '';

                    return PostCard(
                      postSnapshot: postSnapshot,
                      onCommentPressed: () => _onCommentTapped(postSnapshot.id),
                      onDeletePressed: () => _deletePost(postSnapshot.id),
                      onProfileTapped: () => _onProfileTapped(postAuthorId),
                      // Pass the author ID to the like function
                      onLikePressed:
                          () => _toggleLike(
                            postSnapshot.id,
                            currentLikes,
                            postAuthorId,
                          ),
                      onEditPressed:
                          () => _editPost(postSnapshot.id, currentCaption),
                    );
                  }, childCount: posts.length),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- MODIFIED to show Notification button instead of Search ---
  Widget _buildTopBar(Color textColor, Color iconBgColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // This is the new Notification Button
          GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBgColor,
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: textColor,
                size: 28,
              ),
            ),
          ),
          Text(
            'Explore',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatListScreen(),
                  ),
                ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBgColor,
              ),
              child: Icon(Icons.message_outlined, color: textColor, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
