import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'comments_screen.dart';
import 'post_card.dart';
// import 'home_screen.dart'; // <-- FIX #1: REMOVED UNUSED IMPORT

class PostDetailScreen extends StatefulWidget {
  final DocumentSnapshot postSnapshot;
  const PostDetailScreen({super.key, required this.postSnapshot});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  // --- FIX #2: THE CORRECTED DELETE FUNCTION ---
  Future<void> _deletePost(String postId) async {
    // We capture the BuildContext dependent objects BEFORE the first await.
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show a confirmation dialog
    final bool? didRequestDelete = await showDialog<bool>(
      context:
          context, // It's safe to use context here because it's synchronous
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

    // If the user confirmed, proceed with deletion
    if (didRequestDelete == true) {
      try {
        // Delete the post from Firestore
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .delete();

        // Use the captured variables. This is now safe.
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // Use the captured scaffoldMessenger here too.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Post", style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: PostCard(
            postSnapshot: widget.postSnapshot,
            onCommentPressed: () => _onCommentTapped(widget.postSnapshot.id),
            onDeletePressed: () => _deletePost(widget.postSnapshot.id),
          ),
        ),
      ),
    );
  }
}
