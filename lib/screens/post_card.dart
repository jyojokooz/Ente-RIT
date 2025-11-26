// ===============================
// FILE NAME: post_card.dart
// FILE PATH: lib/screens/post_card.dart
// ===============================

// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'full_screen_image_viewer.dart';
import 'full_screen_video_player.dart';

class PostCard extends StatelessWidget {
  final DocumentSnapshot postSnapshot;
  final Function() onCommentPressed;
  final Function() onDeletePressed;
  final Function() onProfileTapped;
  final Function() onLikePressed;
  final Function() onEditPressed;

  const PostCard({
    super.key,
    required this.postSnapshot,
    required this.onCommentPressed,
    required this.onDeletePressed,
    required this.onProfileTapped,
    required this.onLikePressed,
    required this.onEditPressed,
  });

  String getOptimizedCloudinaryUrl(String originalUrl) {
    if (!originalUrl.contains('res.cloudinary.com')) return originalUrl;
    const transformations = 'w_1080,q_auto:good,f_auto';
    final parts = originalUrl.split('/upload/');
    if (parts.length == 2)
      return '${parts[0]}/upload/$transformations/${parts[1]}';
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    final postData = postSnapshot.data() as Map<String, dynamic>?;
    if (postData == null) return const SizedBox.shrink();

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    const Color brandBlack = Colors.black;
    const Color brandPurple = Color(0xFF9983F3);

    final authorData = {
      'displayName': postData['userName'] ?? 'Unknown',
      'username': postData['username'] ?? '',
      'profilePhotoUrl': postData['userImageUrl'] ?? '',
    };

    final String originalMediaUrl =
        postData['postMediaUrl'] ?? postData['postImageUrl'] ?? '';
    final String? originalThumbnailUrl = postData['postThumbnailUrl'];
    final String postType = postData['postType'] ?? 'image';
    final String caption = postData['caption'] ?? '';
    final bool isAuthor = postData['userId'] == currentUserId;
    final timestamp = (postData['timestamp'] as Timestamp?)?.toDate();
    final String heroTag = 'post-${postSnapshot.id}';

    return Container(
      // FIX 1: Reduced vertical margin to 0 so posts stack without gaps
      margin: const EdgeInsets.only(bottom: 1.0),
      decoration: BoxDecoration(
        color: Colors.white,
        // Removed large radius for a continuous feed look
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 10.0,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onProfileTapped,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage:
                        authorData['profilePhotoUrl'].isNotEmpty
                            ? CachedNetworkImageProvider(
                              authorData['profilePhotoUrl'],
                            )
                            : null,
                    child:
                        authorData['profilePhotoUrl'].isEmpty
                            ? const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 20,
                            )
                            : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorData['displayName'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: brandBlack,
                        ),
                      ),
                      if (authorData['username'].isNotEmpty)
                        Text(
                          '@${authorData['username']}',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isAuthor)
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: onEditPressed,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),

          // --- MEDIA ---
          if (originalMediaUrl.isNotEmpty)
            GestureDetector(
              onTap: () {
                if (postType == 'video') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) =>
                              FullScreenVideoPlayer(videoUrl: originalMediaUrl),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => FullScreenImageViewer(
                            imageUrl: originalMediaUrl,
                            heroTag: heroTag,
                          ),
                    ),
                  );
                }
              },
              child: Hero(
                tag: heroTag,
                // FIX 2: ConstrainedBox allows dynamic aspect ratio
                // Max height 500 ensures vertical images don't take entire screen
                // Min height 250 ensures landscape images aren't too thin
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 250,
                    maxHeight: 500,
                    minWidth: double.infinity,
                  ),
                  child: Stack(
                    fit:
                        StackFit
                            .loose, // Allows child to determine size within constraints
                    alignment: Alignment.center,
                    children: [
                      CachedNetworkImage(
                        imageUrl:
                            postType == 'video'
                                ? getOptimizedCloudinaryUrl(
                                  originalThumbnailUrl ?? '',
                                )
                                : getOptimizedCloudinaryUrl(originalMediaUrl),
                        // fitWidth ensures we see the full width of landscape images
                        // while cover handles filling vertical space
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder:
                            (context, url) => Container(
                              height: 300,
                              color: Colors.grey.shade50,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: brandPurple.withOpacity(0.5),
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              height: 300,
                              color: Colors.grey.shade100,
                              child: const Icon(
                                Icons.error_outline,
                                color: Colors.grey,
                              ),
                            ),
                      ),

                      if (postType == 'video')
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // --- ACTIONS ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 10.0,
            ),
            child: StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postSnapshot.id)
                      .snapshots(),
              builder: (context, snapshot) {
                final likesData =
                    snapshot.hasData
                        ? snapshot.data!.data() as Map<String, dynamic>
                        : postData;
                final rtLikes = likesData['likes'] ?? [];
                final bool isLiked = rtLikes.contains(currentUserId);

                return Row(
                  children: [
                    GestureDetector(
                      onTap: onLikePressed,
                      child: Icon(
                        isLiked
                            ? Icons.favorite
                            : Icons.favorite_border_rounded,
                        color: isLiked ? Colors.redAccent : brandBlack,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: onCommentPressed,
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.send_rounded,
                      size: 24,
                    ), // Share placeholder
                    const Spacer(),
                    const Icon(Icons.bookmark_border_rounded, size: 26),
                  ],
                );
              },
            ),
          ),

          // --- LIKES & CAPTION ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('posts')
                          .doc(postSnapshot.id)
                          .snapshots(),
                  builder: (context, snapshot) {
                    final likesData =
                        snapshot.hasData
                            ? snapshot.data!.data() as Map<String, dynamic>
                            : postData;
                    final rtLikes = likesData['likes'] ?? [];
                    if (rtLikes.isEmpty) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text(
                        "${rtLikes.length} likes",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    );
                  },
                ),

                if (caption.isNotEmpty)
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        color: brandBlack,
                        fontSize: 13,
                        height: 1.3,
                      ),
                      children: [
                        TextSpan(
                          text: "${authorData['displayName']} ",
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: caption),
                      ],
                    ),
                  ),

                const SizedBox(height: 4),

                Text(
                  timestamp != null ? timeago_format(timestamp) : '',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Simple timeago helper
  // ignore: non_constant_identifier_names
  String timeago_format(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) return DateFormat('MMM d').format(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
