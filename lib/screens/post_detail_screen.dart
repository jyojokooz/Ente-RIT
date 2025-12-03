// ===============================
// FILE NAME: post_detail_screen.dart
// FILE PATH: lib/screens/post_detail_screen.dart
// ===============================

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import 'comments_screen.dart';
import 'edit_post_screen.dart';
import 'pages/profile_screen.dart';
import 'full_screen_image_viewer.dart';
import 'full_screen_video_player.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final _firestore = FirebaseFirestore.instance;

  String getOptimizedCloudinaryUrl(String originalUrl) {
    if (!originalUrl.contains('res.cloudinary.com')) return originalUrl;
    const transformations = 'w_1080,q_auto:good,f_auto';
    final parts = originalUrl.split('/upload/');
    if (parts.length == 2)
      return '${parts[0]}/upload/$transformations/${parts[1]}';
    return originalUrl;
  }

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
        // Notification logic...
      }
    }
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

  Future<void> _deletePost() async {
    // ... Delete Logic (Same as before) ...
    await _firestore.collection('posts').doc(widget.postId).delete();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Explicit White Background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Post",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('posts').doc(widget.postId).snapshots(),
        builder: (context, snapshot) {
          // --- 1. Loading State (Skeleton) ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _PostDetailSkeleton();
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Post not found",
                style: TextStyle(color: Colors.black),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String userId = data['userId'] ?? '';
          final String userName = data['userName'] ?? 'User';
          final String userImage = data['userImageUrl'] ?? '';
          final String mediaUrl =
              data['postMediaUrl'] ?? data['postImageUrl'] ?? '';
          final String caption = data['caption'] ?? '';
          final String type = data['postType'] ?? 'image';
          final List likes = data['likes'] ?? [];
          final Timestamp? timestamp = data['timestamp'];
          final bool isLiked = likes.contains(user.uid);
          final bool isOwner = userId == user.uid;

          String dateString = '';
          if (timestamp != null)
            dateString = DateFormat('MMMM d, y').format(timestamp.toDate());

          // --- 2. Main Content (Fade In) ---
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics:
                      const BouncingScrollPhysics(), // Smooth Scroll Physics
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => ProfileScreen(userId: userId),
                                    ),
                                  ),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey[200],
                                backgroundImage:
                                    userImage.isNotEmpty
                                        ? CachedNetworkImageProvider(userImage)
                                        : const AssetImage(
                                              'assets/default_avatar.png',
                                            )
                                            as ImageProvider,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                userName,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            if (isOwner)
                              IconButton(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.black,
                                ),
                                onPressed: () => _showOptions(context, caption),
                              ),
                          ],
                        ),
                      ),

                      // Media
                      GestureDetector(
                        onTap: () {
                          if (type == 'video')
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => FullScreenVideoPlayer(
                                      videoUrl: mediaUrl,
                                    ),
                              ),
                            );
                          else
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => FullScreenImageViewer(
                                      imageUrl: mediaUrl,
                                      heroTag: widget.postId,
                                    ),
                              ),
                            );
                        },
                        child: Hero(
                          tag: widget.postId,
                          child: CachedNetworkImage(
                            imageUrl:
                                type == 'video'
                                    ? mediaUrl
                                    : getOptimizedCloudinaryUrl(mediaUrl),
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Container(
                                  height: 300,
                                  color: Colors.grey[100],
                                ),
                          ),
                        ),
                      ),

                      // Actions
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _toggleLike(userId, likes),
                              child: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.black,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => CommentsScreen(
                                            postId: widget.postId,
                                          ),
                                    ),
                                  ),
                              child: const Icon(
                                Icons.chat_bubble_outline,
                                color: Colors.black,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.send,
                              color: Colors.black,
                              size: 26,
                            ),
                          ],
                        ),
                      ),

                      // Caption
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${likes.length} likes',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (caption.isNotEmpty)
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "$userName ",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(text: caption),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              dateString,
                              style: GoogleFonts.poppins(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Comment Bar
              _buildBottomCommentBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomCommentBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        color: Colors.white,
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: GestureDetector(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CommentsScreen(postId: widget.postId),
              ),
            ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : const AssetImage('assets/default_avatar.png')
                          as ImageProvider,
            ),
            const SizedBox(width: 12),
            Text(
              "Write a comment...",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, String caption) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder:
          (c) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text("Edit"),
                  onTap: () {
                    Navigator.pop(c);
                    _editPost(caption);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(c);
                    _deletePost();
                  },
                ),
              ],
            ),
          ),
    );
  }
}

// --- SKELETON LOADER (Prevents Jitter) ---
class _PostDetailSkeleton extends StatelessWidget {
  const _PostDetailSkeleton();
  @override
  Widget build(BuildContext context) {
    final base = Colors.grey[300]!;
    final highlight = Colors.grey[100]!;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Container(width: 100, height: 12, color: Colors.white),
              ],
            ),
          ),
          Container(width: double.infinity, height: 350, color: Colors.white),
        ],
      ),
    );
  }
}
