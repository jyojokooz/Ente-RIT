// ===============================
// FILE PATH: lib/screens/post_detail_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'post_card.dart';
import 'post_card_placeholder.dart';
import 'comments_sheet.dart';
import 'edit_post_screen.dart';
import 'pages/profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final _firestore = FirebaseFirestore.instance;

  Future<void> _toggleLike(
    String postAuthorId,
    List<dynamic> currentLikes,
  ) async {
    final postRef = _firestore.collection('posts').doc(widget.postId);
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
          'relatedDocId': widget.postId,
          'triggeringUserId': user.uid,
          'triggeringUserName': userData['displayName'] ?? 'User',
          'triggeringUserAvatarUrl': userData['profilePhotoUrl'] ?? '',
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // --- UPDATED: Passing tags ---
  void _editPost(String currentCaption, List<String> currentTags) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditPostScreen(
              postId: widget.postId,
              initialCaption: currentCaption,
              initialTaggedUsers: currentTags,
            ),
      ),
    );
  }

  Future<void> _deletePost() async {
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
        await _firestore.collection('posts').doc(widget.postId).delete();
        if (mounted) Navigator.pop(context); // Go back after deletion
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  void _onCommentTapped() {
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
            child: CommentsSheet(postId: widget.postId),
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
          "Post",
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('posts').doc(widget.postId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SingleChildScrollView(child: PostCardPlaceholder());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Post not found",
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final postData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                PostCard(
                  postSnapshot: snapshot.data!,
                  onCommentPressed: _onCommentTapped,
                  onDeletePressed: _deletePost,
                  onProfileTapped:
                      () => _onProfileTapped(postData['userId'] ?? ''),
                  onLikePressed:
                      () => _toggleLike(
                        postData['userId'] ?? '',
                        postData['likes'] ?? [],
                      ),
                  // --- UPDATED: Pass current tags ---
                  onEditPressed:
                      () => _editPost(
                        postData['caption'] ?? '',
                        List<String>.from(postData['taggedUsers'] ?? []),
                      ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
