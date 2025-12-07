// ===============================
// FILE NAME: home_screen.dart
// FILE PATH: lib/screens/pages/home_screen.dart
// ===============================

// ignore_for_file: curly_braces_in_flow_control_structures

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

  Route _createSmoothRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutQuart),
        );
        var scaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutQuart),
        );
        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
    );
  }

  void _editPost(String postId, String currentCaption) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditPostScreen(postId: postId, initialCaption: currentCaption),
      ),
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
            'Are you sure you want to permanently remove this post?',
            style: GoogleFonts.poppins(color: Colors.grey[800]),
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
        await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
        if (mounted)
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Post deleted.'),
              backgroundColor: Colors.black,
            ),
          );
      } catch (e) {
        if (scaffoldMessenger.mounted)
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Failed to delete: ${e.toString()}')),
          );
      }
    }
  }

  // --- UPDATED _toggleLike FUNCTION ---
  Future<void> _toggleLike(
    String postId,
    List<dynamic> currentLikes,
    String postAuthorId,
  ) async {
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    final isLiked = currentLikes.contains(user.uid);

    if (isLiked) {
      // User is unliking
      await postRef.update({
        'likes': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      // User is liking
      await postRef.update({
        'likes': FieldValue.arrayUnion([user.uid]),
      });

      // --- CREATE NOTIFICATION LOGIC ---
      // Don't send a notification if you like your own post
      if (postAuthorId != user.uid) {
        // Get current user's details to show in the notification
        final currentUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final currentUserData = currentUserDoc.data() ?? {};

        // Create the notification document
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': postAuthorId, // The recipient of the notification
          'title': 'New Like',
          'body': '${currentUserData['displayName'] ?? 'Someone'} liked your post.',
          'type': 'like',
          'relatedDocId': postId, // Link to the post
          'triggeringUserId': user.uid,
          'triggeringUserName': currentUserData['displayName'] ?? 'Someone',
          'triggeringUserAvatarUrl': currentUserData['profilePhotoUrl'] ?? '',
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

  @override
  Widget build(BuildContext context) {
    const Color brandPurple = Color(0xFF9983F3);

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        color: brandPurple,
        backgroundColor: Colors.white,
        child: SafeArea(
          child: CustomScrollView(
            cacheExtent: 1000,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildTopBar()),

              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('posts')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(child: Text("Something went wrong")),
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
                                color: Colors.grey[400],
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
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final postSnapshot = posts[index];
                        final postData =
                            postSnapshot.data() as Map<String, dynamic>;
                        final postAuthorId = postData['userId'] ?? '';
                        final currentLikes = postData['likes'] ?? [];
                        final currentCaption = postData['caption'] ?? '';

                        return PostCard(
                          key: ValueKey(postSnapshot.id),
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
                      },
                      childCount: posts.length,
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Ente RIT',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),

          Row(
            children: [
              NotificationBadge(
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      _createSmoothRoute(const NotificationsScreen()),
                    );
                  },
                  icon: const Icon(
                    Icons.favorite_border,
                    color: Colors.black,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    _createSmoothRoute(const ChatListScreen()),
                  );
                },
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.black,
                  size: 26,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}