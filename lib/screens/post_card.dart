// ===============================
// FILE NAME: post_card.dart
// FILE PATH: lib/screens/post_card.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
    if (!originalUrl.contains('res.cloudinary.com')) {
      return originalUrl;
    }
    const transformations = 'w_1280,q_auto:best,f_auto';
    final parts = originalUrl.split('/upload/');
    if (parts.length == 2) {
      return '${parts[0]}/upload/$transformations/${parts[1]}';
    }
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    final postData = postSnapshot.data() as Map<String, dynamic>?;
    if (postData == null) return const SizedBox.shrink();

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    const Color brandBlack = Colors.black;
    const Color brandWhite = Colors.white;
    const Color brandPurple = Color(0xFF9983F3);

    final authorData = {
      'displayName': postData['userName'] ?? 'UNKNOWN_USER',
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
    final String heroTag = 'postImage-${postSnapshot.id}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: brandWhite,
        // FIX: More rounded corners (24 instead of 0 or 16)
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: brandBlack, width: 3),
        boxShadow: const [
          BoxShadow(color: brandBlack, offset: Offset(8, 8), blurRadius: 0),
        ],
      ),
      clipBehavior: Clip.antiAlias, // Ensures content clips to rounded corners
      child: Stack(
        children: [
          // --- DECORATIVE CORNER BOLTS (Adjusted for curves) ---
          Positioned(top: 12, left: 12, child: _buildBolt(brandBlack)),
          Positioned(top: 12, right: 12, child: _buildBolt(brandBlack)),
          Positioned(bottom: 12, left: 12, child: _buildBolt(brandBlack)),
          Positioned(bottom: 12, right: 12, child: _buildBolt(brandBlack)),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. TECH HEADER ---
              Container(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  12,
                ), // More padding for curves
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: brandBlack, width: 2),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: onProfileTapped,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape:
                              BoxShape
                                  .circle, // Circular avatar fits rounded theme better
                          border: Border.all(color: brandBlack, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              authorData['profilePhotoUrl'].isNotEmpty
                                  ? NetworkImage(authorData['profilePhotoUrl'])
                                  : null,
                          child:
                              authorData['profilePhotoUrl'].isEmpty
                                  ? const Icon(
                                    Icons.person,
                                    color: brandBlack,
                                    size: 20,
                                  )
                                  : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authorData['displayName'].toUpperCase(),
                            style: GoogleFonts.spaceMono(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: brandBlack,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (authorData['username'].isNotEmpty)
                            Text(
                              '// @${authorData['username']}',
                              style: GoogleFonts.firaCode(
                                color: Colors.grey.shade700,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isAuthor)
                      GestureDetector(
                        onTap: onEditPressed,
                        child: const Icon(
                          Icons.settings_outlined,
                          color: brandBlack,
                          size: 22,
                        ),
                      ),
                  ],
                ),
              ),

              // --- 2. MEDIA DISPLAY ---
              if (originalMediaUrl.isNotEmpty)
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Colors.black),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 200,
                      maxHeight: 550,
                    ),
                    child:
                        (postType == 'video')
                            ? _buildVideoPlayer(
                              context,
                              originalMediaUrl,
                              originalThumbnailUrl,
                            )
                            : _buildImageViewer(
                              context,
                              originalMediaUrl,
                              heroTag,
                            ),
                  ),
                ),

              // --- 3. TECH FOOTER & ACTIONS ---
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: brandBlack, width: 2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreamBuilder<DocumentSnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('posts')
                              .doc(postSnapshot.id)
                              .snapshots(),
                      builder: (context, postStreamSnapshot) {
                        final likesData =
                            postStreamSnapshot.hasData
                                ? postStreamSnapshot.data!.data()
                                    as Map<String, dynamic>
                                : postData;
                        final rtLikes = likesData['likes'] ?? [];
                        final bool isLiked = rtLikes.contains(currentUserId);

                        return StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(postSnapshot.id)
                                  .collection('comments')
                                  .snapshots(),
                          builder: (context, commentStreamSnapshot) {
                            final commentCount =
                                commentStreamSnapshot.hasData
                                    ? commentStreamSnapshot.data!.docs.length
                                    : (postData['comments'] ?? 0);

                            return Row(
                              children: [
                                // TECH LIKE BUTTON (Rounded)
                                GestureDetector(
                                  onTap: onLikePressed,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isLiked ? brandPurple : Colors.white,
                                      border: Border.all(
                                        color: brandBlack,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        20,
                                      ), // Rounded pill
                                      boxShadow: const [
                                        BoxShadow(
                                          color: brandBlack,
                                          offset: Offset(2, 2),
                                          blurRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          size: 18,
                                          color:
                                              isLiked
                                                  ? Colors.white
                                                  : brandBlack,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "${rtLikes.length}",
                                          style: GoogleFonts.spaceMono(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color:
                                                isLiked
                                                    ? Colors.white
                                                    : brandBlack,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // TECH COMMENT BUTTON (Rounded)
                                GestureDetector(
                                  onTap: onCommentPressed,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      border: Border.all(
                                        color: brandBlack,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        20,
                                      ), // Rounded pill
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.grey,
                                          offset: Offset(2, 2),
                                          blurRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.chat_bubble_outline,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "$commentCount",
                                          style: GoogleFonts.spaceMono(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),

                    if (caption.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.only(left: 10),
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(color: brandPurple, width: 4),
                          ),
                        ),
                        child: Text(
                          caption,
                          style: GoogleFonts.spaceMono(
                            color: brandBlack,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // DATE STAMP
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        timestamp != null
                            ? "LOG: ${DateFormat('yyyy-MM-dd HH:mm').format(timestamp)}"
                            : "LOG: UNKNOWN",
                        style: GoogleFonts.firaCode(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBolt(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle, // Changed to circle for rounded theme
      ),
    );
  }

  Widget _buildImageViewer(
    BuildContext context,
    String originalImageUrl,
    String heroTag,
  ) {
    final String optimizedUrl = getOptimizedCloudinaryUrl(originalImageUrl);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => FullScreenImageViewer(
                  imageUrl: originalImageUrl,
                  heroTag: heroTag,
                ),
          ),
        );
      },
      child: Hero(
        tag: heroTag,
        child: Image.network(
          optimizedUrl,
          fit: BoxFit.fitWidth,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 200,
              color: Colors.grey.shade900,
              child: const Center(
                child: Icon(Icons.image_search, color: Colors.white54),
              ),
            );
          },
          errorBuilder:
              (context, error, stackTrace) => Container(
                height: 200,
                color: Colors.grey.shade900,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      "IMG_ERR",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(
    BuildContext context,
    String originalVideoUrl,
    String? originalThumbnailUrl,
  ) {
    final String optimizedThumbnailUrl =
        originalThumbnailUrl != null
            ? getOptimizedCloudinaryUrl(originalThumbnailUrl)
            : 'https://via.placeholder.com/600x600/000000/FFFFFF/?text=NO_SIGNAL';
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      FullScreenVideoPlayer(videoUrl: originalVideoUrl),
            ),
          ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.network(
            optimizedThumbnailUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder:
                (context, error, stackTrace) =>
                    Container(height: 200, color: Colors.grey.shade900),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Icon(Icons.play_arrow, color: Colors.black, size: 30),
          ),
        ],
      ),
    );
  }
}
