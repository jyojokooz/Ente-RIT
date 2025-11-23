// ===============================
// FILE NAME: home_screen.dart
// FILE PATH: lib/screens/pages/home_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Screen Imports ---
import '../comments_screen.dart';
import '../edit_post_screen.dart';
import '../notifications_screen.dart';
import '../chat_list_screen.dart';
import '../post_card.dart';
import '../post_card_placeholder.dart';
import 'profile_screen.dart';

// --- Widget Imports ---
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
          backgroundColor: Colors.white,
          title: Text(
            'Delete Post?',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to permanently delete this post?',
            style: GoogleFonts.poppins(color: Colors.grey[700]),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
              content: Text('Post deleted.'),
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
    // Theme Colors
    const Color brandPurple = Color(0xFF9983F3);
    const Color bgColor = Colors.white; // Changed to White

    return Scaffold(
      backgroundColor: bgColor, // Set Scaffold background
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        color: brandPurple,
        backgroundColor: Colors.white,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildTopBar()),
              // removed the SizedBox to pull content up slightly
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
                        (context, index) =>
                            const PostCardPlaceholder(), // Make sure placeholder is also updated for light theme
                        childCount: 5,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'Something went wrong!',
                          style: GoogleFonts.poppins(color: Colors.redAccent),
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.post_add,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No posts yet.',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                          ],
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
                        onCommentPressed:
                            () => _onCommentTapped(postSnapshot.id),
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
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ), // Bottom padding for scrolling past FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // --- TITLE ---
          Text(
            'Explore',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black, // Dark text
              letterSpacing: -0.5,
            ),
          ),

          // --- ACTIONS ---
          Row(
            children: [
              NotificationBadge(
                child: IconButton(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      ),
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.black87,
                    size: 26,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatListScreen(),
                      ),
                    ),
                icon: const Icon(
                  Icons.message_outlined,
                  color: Colors.black87,
                  size: 26,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
