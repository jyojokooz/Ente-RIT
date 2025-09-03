import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'comments_screen.dart';
import 'edit_post_screen.dart';
import 'post_card.dart';
import 'pages/profile_screen.dart';
import 'post_card_placeholder.dart'; // <-- 1. IMPORT THE SHIMMER PLACEHOLDER

class PostDetailScreen extends StatefulWidget {
  final DocumentSnapshot postSnapshot;
  const PostDetailScreen({super.key, required this.postSnapshot});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  // All the methods (_toggleLike, _editPost, _deletePost, etc.) are
  // well-written and don't need to be changed. The optimization is in the UI structure.

  Future<void> _toggleLike() async {
    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postSnapshot.id);
    final user = FirebaseAuth.instance.currentUser!;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final freshSnap = await transaction.get(postRef);
      if (!freshSnap.exists) {
        throw Exception("Post does not exist!");
      }
      final List<dynamic> currentLikes =
          (freshSnap.data() as Map<String, dynamic>)['likes'] ?? [];
      final isLiked = currentLikes.contains(user.uid);

      if (isLiked) {
        transaction.update(postRef, {
          'likes': FieldValue.arrayRemove([user.uid]),
        });
      } else {
        transaction.update(postRef, {
          'likes': FieldValue.arrayUnion([user.uid]),
        });
      }
    });
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

  Future<void> _deletePost(String postId) async {
    final navigator = Navigator.of(context);
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
        if (navigator.canPop()) {
          navigator.pop();
        }
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

  @override
  Widget build(BuildContext context) {
    // We get static data like authorId once to avoid fetching it in the StreamBuilder.
    final postData = widget.postSnapshot.data() as Map<String, dynamic>;
    final postAuthorId = postData['userId'] ?? '';

    // --- 2. OPTIMIZED STRUCTURE ---
    // The Scaffold and AppBar are now built only ONCE. They are no longer inside
    // the StreamBuilder, preventing unnecessary rebuilds.
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Post", style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      // The StreamBuilder now only wraps the body content that needs to be updated.
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('posts')
                .doc(widget.postSnapshot.id)
                .snapshots(),
        builder: (context, snapshot) {
          // --- 3. IMPROVED LOADING STATE ---
          // While waiting for the post data, we show our professional shimmer placeholder.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: PostCardPlaceholder(),
              ),
            );
          }

          // Handle the case where the post was deleted while the user is viewing it.
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'This post has been deleted.',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            );
          }

          final updatedPostSnapshot = snapshot.data!;
          final updatedPostData =
              updatedPostSnapshot.data() as Map<String, dynamic>;
          final currentCaption = updatedPostData['caption'] ?? '';

          // This part only rebuilds when the post data actually changes.
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: PostCard(
                postSnapshot: updatedPostSnapshot,
                onCommentPressed:
                    () => _onCommentTapped(updatedPostSnapshot.id),
                onDeletePressed: () => _deletePost(updatedPostSnapshot.id),
                onProfileTapped: () => _onProfileTapped(postAuthorId),
                onLikePressed: _toggleLike,
                onEditPressed:
                    () => _editPost(updatedPostSnapshot.id, currentCaption),
              ),
            ),
          );
        },
      ),
    );
  }
}
