// lib/screens/admin/admin_manage_posts_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminManagePostsScreen extends StatefulWidget {
  const AdminManagePostsScreen({super.key});

  @override
  State<AdminManagePostsScreen> createState() => _AdminManagePostsScreenState();
}

class _AdminManagePostsScreenState extends State<AdminManagePostsScreen> {
  // Method for deleting a post
  Future<void> _deletePost(String postId) async {
    final bool? didRequestDelete = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.grey.shade800,
            title: const Text('Delete Post?'),
            content: const Text('Are you sure you want to delete this post?'),
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
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Manage Posts', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('posts')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final postData = posts[index].data() as Map<String, dynamic>;
              final timestamp = (postData['timestamp'] as Timestamp?)?.toDate();
              return Card(
                color: Colors.grey.shade900,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            postData['postImageUrl'] != null &&
                                    postData['postImageUrl'].isNotEmpty
                                ? Image.network(
                                  postData['postImageUrl'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                )
                                : Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey.shade800,
                                  child: const Icon(Icons.image_not_supported),
                                ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              postData['caption'] ?? 'No caption',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'by ${postData['userName']} • ${timestamp != null ? timeago.format(timestamp) : '...'}',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _deletePost(posts[index].id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
