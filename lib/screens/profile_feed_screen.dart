// ===============================
// FILE PATH: lib/screens/profile_feed_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'post_card.dart';
import 'comments_sheet.dart';
import 'edit_post_screen.dart';

class ProfileFeedScreen extends StatefulWidget {
  final List<DocumentSnapshot> posts;
  final int initialIndex;

  const ProfileFeedScreen({
    super.key,
    required this.posts,
    required this.initialIndex,
  });

  @override
  State<ProfileFeedScreen> createState() => _ProfileFeedScreenState();
}

class _ProfileFeedScreenState extends State<ProfileFeedScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final _firestore = FirebaseFirestore.instance;

  // The Center Key is the magic trick in Flutter that tells a CustomScrollView
  // exactly where to start its viewport!
  final Key _centerKey = const ValueKey('center-post');

  Future<void> _toggleLike(
    String postId,
    List<dynamic> currentLikes,
    String postAuthorId,
  ) async {
    final postRef = _firestore.collection('posts').doc(postId);
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
            await _firestore.collection('users').doc(user.uid).get();
        final userData = userDoc.data() ?? {};

        await _firestore.collection('notifications').add({
          'userId': postAuthorId,
          'title': 'New Like',
          'body': '${userData['displayName'] ?? 'Someone'} liked your post.',
          'type': 'like',
          'relatedDocId': postId,
          'triggeringUserId': user.uid,
          'triggeringUserName': userData['displayName'] ?? 'User',
          'triggeringUserAvatarUrl': userData['profilePhotoUrl'] ?? '',
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  void _editPost(
    String postId,
    String currentCaption,
    List<String> currentTags,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditPostScreen(
              postId: postId,
              initialCaption: currentCaption,
              initialTaggedUsers: currentTags,
            ),
      ),
    );
  }

  Future<void> _deletePost(String postId) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bool? didRequestDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF252528) : Colors.white,
          title: Text(
            'Delete Post?',
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to permanently remove this post?',
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white70 : Colors.black54,
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
        await _firestore.collection('posts').doc(postId).delete();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Post deleted.')));
          Navigator.pop(context); // Pop out of feed to prevent index errors
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
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
    // If they tap the profile picture, just pop back (since they are already on the profile)
    Navigator.pop(context);
  }

  Widget _buildPostCard(int index) {
    final postSnapshot = widget.posts[index];
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
          () => _editPost(
            postSnapshot.id,
            postData['caption'] ?? '',
            List<String>.from(postData['taggedUsers'] ?? []),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Posts",
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          center:
              _centerKey, // MAGIC: This makes the view start at the center sliver!
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Posts BEFORE the tapped post (allows scrolling UP)
            if (widget.initialIndex > 0)
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  // Index 0 here is the item immediately above the center
                  final realIndex = widget.initialIndex - 1 - index;
                  return _buildPostCard(realIndex);
                }, childCount: widget.initialIndex),
              ),

            // 2. The TAPPED post and all subsequent posts (allows scrolling DOWN)
            SliverList(
              key: _centerKey,
              delegate: SliverChildBuilderDelegate((context, index) {
                final realIndex = widget.initialIndex + index;
                return Column(
                  children: [
                    _buildPostCard(realIndex),
                    // Add padding at the very end of the list
                    if (realIndex == widget.posts.length - 1)
                      const SizedBox(height: 80),
                  ],
                );
              }, childCount: widget.posts.length - widget.initialIndex),
            ),
          ],
        ),
      ),
    );
  }
}
