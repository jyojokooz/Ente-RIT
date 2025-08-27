import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'comments_screen.dart';
import 'edit_post_screen.dart'; // <-- 1. IMPORT THE EDIT SCREEN
import 'post_card.dart';
import 'profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final DocumentSnapshot postSnapshot;
  const PostDetailScreen({super.key, required this.postSnapshot});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Future<void> _toggleLike() async {
    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postSnapshot.id);
    final user = FirebaseAuth.instance.currentUser!;

    // Use a transaction to get the most up-to-date data before writing
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

  // --- 2. ADD THE EDIT POST FUNCTION ---
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
        // Check if the screen can be popped before popping
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
    // We can get static data once here, like the author ID.
    final postData = widget.postSnapshot.data() as Map<String, dynamic>;
    final postAuthorId = postData['userId'] ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Post", style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('posts')
                .doc(widget.postSnapshot.id)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }
          // If the post was deleted while the user is viewing it
          if (!snapshot.data!.exists) {
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
                // --- 3. ADD THE MISSING onEditPressed ARGUMENT ---
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
