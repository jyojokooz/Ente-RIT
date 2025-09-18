import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Screen Imports (Corrected Paths) ---
// Go up one level from 'pages' to 'screens' to find these files.
import '../comments_screen.dart';
import '../edit_post_screen.dart';
import '../notifications_screen.dart';
import '../chat_list_screen.dart';
import 'profile_screen.dart'; // This one is in the same 'pages' folder

// --- Widget Imports (Corrected Paths) ---
// Go up two levels from 'pages' to 'lib', then into 'widgets'.
import '../post_card.dart';
import '../post_card_placeholder.dart';
import '../../widgets/notification_badge.dart';

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

  /// Handles liking/unliking a post and creates a notification on like.
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

      if (postAuthorId != user.uid) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': postAuthorId,
          'title': 'New Like',
          'body': '${user.displayName ?? 'Someone'} liked your post.',
          'type': 'like',
          'relatedDocId': postId,
          'isRead': false,
          'isDelivered': false,
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
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Post deleted successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        }
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

  /// Builds the top bar with the notification button and chat button.
  Widget _buildTopBar(Color textColor, Color iconBgColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          NotificationBadge(
            child: GestureDetector(
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
