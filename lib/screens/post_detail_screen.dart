import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'post_card.dart';
import 'post_card_placeholder.dart';
import 'comments_screen.dart';
import 'edit_post_screen.dart';
// Make sure this path is correct for your project structure
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

      // Add notification if someone else likes the post
      if (postAuthorId != user.uid) {
        await _firestore.collection('notifications').add({
          'userId': postAuthorId,
          'title': 'New Like',
          'body': '${user.displayName ?? 'Someone'} liked your post.',
          'type': 'like',
          'relatedDocId': widget.postId,
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  void _onCommentTapped() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(postId: widget.postId),
      ),
    );
  }

  void _onProfileTapped(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen(userId: userId)),
    );
  }

  void _editPost(String currentCaption) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditPostScreen(
              postId: widget.postId,
              initialCaption: currentCaption,
            ),
      ),
    );
  }

  // --- THIS FUNCTION HAS BEEN UPDATED ---
  Future<void> _deletePost() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final bool? didRequestDelete = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.grey.shade900,
            title: const Text(
              'Delete Post?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to permanently delete this post?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (didRequestDelete == true) {
      try {
        await _firestore.collection('posts').doc(widget.postId).delete();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Post deleted.'),
            backgroundColor: Colors.green,
          ),
        );
        if (navigator.canPop()) {
          // *** THE FIX IS HERE ***
          // Instead of a simple pop(), we pop with a result map.
          // This tells the previous screen (the feed) what happened.
          navigator.pop({'action': 'deleted', 'postId': widget.postId});
        }
      } catch (e) {
        if (scaffoldMessenger.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Failed to delete post: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Added for consistent theme
      appBar: AppBar(
        title: Text("Post", style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('posts').doc(widget.postId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SingleChildScrollView(child: PostCardPlaceholder());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Error loading post.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                "Post not found.\nIt may have been deleted.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            );
          }

          final postSnapshot = snapshot.data!;
          final postData = postSnapshot.data() as Map<String, dynamic>;
          final postAuthorId = postData['userId'] ?? '';
          final currentLikes = postData['likes'] ?? [];
          final currentCaption = postData['caption'] ?? '';

          return SingleChildScrollView(
            child: PostCard(
              postSnapshot: postSnapshot,
              onCommentPressed: _onCommentTapped,
              onDeletePressed: _deletePost,
              onProfileTapped: () => _onProfileTapped(postAuthorId),
              onLikePressed: () => _toggleLike(postAuthorId, currentLikes),
              onEditPressed: () => _editPost(currentCaption),
            ),
          );
        },
      ),
    );
  }
}
