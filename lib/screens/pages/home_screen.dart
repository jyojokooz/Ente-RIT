// =
// FILE NAME: home_screen.dart
// FILE PATH: lib/screens/pages/home_screen.dart
// =

// ignore_for_file: curly_braces_in_flow_control_structures, duplicate_ignore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser!;
  AnimationController? _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController?.dispose();
    super.dispose();
  }

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
      // Unlike the post
      await postRef.update({
        'likes': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      // Like the post
      await postRef.update({
        'likes': FieldValue.arrayUnion([user.uid]),
      });

      // --- NEW NOTIFICATION LOGIC ---
      if (postAuthorId != user.uid) {
        // Fetch details of the current user (who liked the post)
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        // Fetch the post to get its thumbnail
        final postDoc =
            await FirebaseFirestore.instance
                .collection('posts')
                .doc(postId)
                .get();

        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': postAuthorId, // The user who will receive the notification
          'title': 'New Like', // Replaced with dynamic body
          'body':
              '${userDoc.data()?['displayName'] ?? 'Someone'} liked your post.',
          'type': 'like',
          'relatedDocId': postId,
          'triggeringUserId': user.uid,
          'triggeringUserName': userDoc.data()?['displayName'] ?? 'Someone',
          'triggeringUserAvatarUrl': userDoc.data()?['profilePhotoUrl'] ?? '',
          'postThumbnailUrl':
              postDoc.data()?['postThumbnailUrl'] ??
              postDoc.data()?['postMediaUrl'] ??
              '',
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
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.black, width: 2),
          ),
          title: Text(
            'Delete Post?',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure?',
            style: GoogleFonts.poppins(color: Colors.grey[800]),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
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
        if (mounted)
          // ignore: curly_braces_in_flow_control_structures
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Post deleted.'),
              backgroundColor: Colors.green,
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

  @override
  Widget build(BuildContext context) {
    const Color brandPurple = Color(0xFF9983F3);

    if (_bgController == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(color: Colors.white),

          AnimatedBuilder(
            animation: _bgController!,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -50 + (_bgController!.value * 20),
                    left: -50,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: brandPurple.withAlpha(60),
                        boxShadow: [
                          BoxShadow(
                            color: brandPurple.withAlpha(60),
                            blurRadius: 100,
                            spreadRadius: 50,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 100 - (_bgController!.value * 30),
                    right: -80,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.yellow.withAlpha(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellow.withAlpha(40),
                            blurRadius: 80,
                            spreadRadius: 40,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          Positioned(top: 100, right: 20, child: _buildSquiggle(Colors.black)),
          Positioned(
            bottom: 200,
            left: 20,
            child: Transform.rotate(
              angle: math.pi,
              child: _buildSquiggle(Colors.black54),
            ),
          ),

          RefreshIndicator(
            onRefresh: _refreshPosts,
            color: brandPurple,
            backgroundColor: Colors.white,
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildTopBar()),

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
                            (context, index) => const PostCardPlaceholder(),
                            childCount: 5,
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
                                  color: Colors.grey[400],
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

                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            builder:
                                (context, value, child) =>
                                    Opacity(opacity: value, child: child),
                            child: PostCard(
                              postSnapshot: postSnapshot,
                              onCommentPressed:
                                  () => _onCommentTapped(postSnapshot.id),
                              onDeletePressed:
                                  () => _deletePost(postSnapshot.id),
                              onProfileTapped:
                                  () => _onProfileTapped(postAuthorId),
                              onLikePressed:
                                  () => _toggleLike(
                                    postSnapshot.id,
                                    currentLikes,
                                    postAuthorId,
                                  ),
                              onEditPressed:
                                  () => _editPost(
                                    postSnapshot.id,
                                    currentCaption,
                                  ),
                            ),
                          );
                        }, childCount: posts.length),
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Kampus Konnect',
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
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      ),
                  icon: const Icon(
                    Icons.favorite_border,
                    color: Colors.black,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatListScreen(),
                      ),
                    ),
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

  Widget _buildSquiggle(Color color) {
    return SizedBox(
      width: 60,
      height: 20,
      child: CustomPaint(painter: _SquigglePainter(color)),
    );
  }
}

class _SquigglePainter extends CustomPainter {
  final Color color;
  _SquigglePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
    final path = Path();
    path.moveTo(0, size.height / 2);
    path.quadraticBezierTo(
      size.width * 0.25,
      0,
      size.width * 0.5,
      size.height / 2,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height,
      size.width,
      size.height / 2,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
