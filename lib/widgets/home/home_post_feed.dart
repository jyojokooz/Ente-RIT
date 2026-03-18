// ===============================
// FILE NAME: home_post_feed.dart
// FILE PATH: lib/widgets/home/home_post_feed.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../screens/post_card.dart';
import '../../screens/post_card_placeholder.dart';
import '../../screens/comments_sheet.dart';
import '../../screens/edit_post_screen.dart';
import '../../screens/pages/profile_screen.dart';

class HomePostFeed extends StatefulWidget {
  final int selectedTab;
  final Color textColor;

  const HomePostFeed({
    super.key,
    required this.selectedTab,
    required this.textColor,
  });

  @override
  State<HomePostFeed> createState() => _HomePostFeedState();
}

class _HomePostFeedState extends State<HomePostFeed> {
  final user = FirebaseAuth.instance.currentUser!;

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

  Future<void> _deletePost(String postId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    final bool? didRequestDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            'Delete Post?',
            style: GoogleFonts.poppins(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to permanently remove this post?',
            style: GoogleFonts.poppins(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
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
            SnackBar(
              content: const Text('Post deleted.'),
              backgroundColor: theme.colorScheme.onSurface,
            ),
          );
        }
      } catch (e) {
        if (scaffoldMessenger.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

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
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        final userData = userDoc.data();
        final displayName = userData?['displayName'] ?? 'User';
        final profilePic = userData?['profilePhotoUrl'] ?? '';

        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': postAuthorId,
          'title': 'New Like',
          'body': '$displayName liked your post.',
          'type': 'like',
          'relatedDocId': postId,
          'triggeringUserId': user.uid,
          'triggeringUserName': displayName,
          'triggeringUserAvatarUrl': profilePic,
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  void _onCommentTapped(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: CommentsSheet(postId: postId),
          ),
    );
  }

  void _onProfileTapped(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('posts')
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                "Error loading posts",
                style: TextStyle(color: widget.textColor),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => const PostCardPlaceholder(),
              childCount: 3,
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'No posts yet.',
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
              ),
            ),
          );
        }

        // --- FIX IMPLEMENTED HERE ---
        // Explicitly typed as List<DocumentSnapshot> to prevent assignment errors
        List<DocumentSnapshot> posts = snapshot.data!.docs;

        // Apply "Trending" sorting if the Trending tab is selected
        if (widget.selectedTab == 1) {
          // Re-assign the list as a modifiable copy so we can sort it
          posts = List<DocumentSnapshot>.from(posts);
          posts.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aLikes = (aData['likes'] as List?)?.length ?? 0;
            final bLikes = (bData['likes'] as List?)?.length ?? 0;
            return bLikes.compareTo(aLikes);
          });
        }
        // --- END OF FIX ---

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final postSnapshot = posts[index];
            final postData = postSnapshot.data() as Map<String, dynamic>;

            return PostCard(
              key: ValueKey(postSnapshot.id),
              postSnapshot: postSnapshot,
              onCommentPressed: () => _onCommentTapped(postSnapshot.id),
              onDeletePressed: () => _deletePost(postSnapshot.id),
              onProfileTapped: () => _onProfileTapped(postData['userId'] ?? ''),
              onLikePressed:
                  () => _toggleLike(
                    postSnapshot.id,
                    postData['likes'] ?? [],
                    postData['userId'] ?? '',
                  ),
              onEditPressed:
                  () => _editPost(postSnapshot.id, postData['caption'] ?? ''),
            );
          }, childCount: posts.length),
        );
      },
    );
  }
}
