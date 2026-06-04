// ===============================
// FILE NAME: explore_trending_grid.dart
// FILE PATH: lib/features/explore/presentation/widgets/explore_trending_grid.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:my_project/core/widgets/full_screen_video_player.dart';
import 'package:my_project/core/widgets/full_screen_image_viewer.dart';

class ExploreTrendingGrid extends StatelessWidget {
  final String currentUserId;
  final List<dynamic> myConnections;
  final Color cardColor;
  final Color subtitleColor;
  final bool isDark;

  const ExploreTrendingGrid({
    super.key,
    required this.currentUserId,
    required this.myConnections,
    required this.cardColor,
    required this.subtitleColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('posts')
              .orderBy('timestamp', descending: true)
              .limit(50)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF3E8E)),
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
                    Icons.grid_view_rounded,
                    size: 50,
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No trending posts yet.',
                    style: GoogleFonts.poppins(color: subtitleColor),
                  ),
                ],
              ),
            ),
          );
        }

        final visibleDocs =
            snapshot.data!.docs.where((postDoc) {
              final data = postDoc.data() as Map<String, dynamic>;
              final authorId = data['userId'];
              final isPrivate = data['isAuthorPrivate'] ?? false;
              if (authorId == currentUserId) return true;
              if (!isPrivate) return true;
              return myConnections.contains(authorId);
            }).toList();

        visibleDocs.sort((a, b) {
          final aLikes =
              ((a.data() as Map<String, dynamic>)['likes'] as List<dynamic>? ??
                      [])
                  .length;
          final bLikes =
              ((b.data() as Map<String, dynamic>)['likes'] as List<dynamic>? ??
                      [])
                  .length;
          return bLikes.compareTo(aLikes);
        });

        if (visibleDocs.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                'No trending posts available.',
                style: GoogleFonts.poppins(color: subtitleColor),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ).copyWith(bottom: 80),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75, // Taller to fit text cleanly
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final postDoc = visibleDocs[index];
              final data = postDoc.data() as Map<String, dynamic>;

              final likesCount = (data['likes'] as List<dynamic>? ?? []).length;
              final commentsCount = data['comments'] ?? 0;
              final isVideo = data['postType'] == 'video';

              // --- FIX: Safely extract image length to calculate imageCount ---
              final imagesList = data['postImages'] as List<dynamic>? ?? [];
              final int imageCount = imagesList.length;
              final bool isMultiImage = imageCount > 1;

              // Text extraction
              final caption = data['caption']?.toString().trim() ?? '';
              final title =
                  caption.isNotEmpty ? caption.split('\n').first : 'Post';

              final thumbnailUrl =
                  isVideo
                      ? data['postThumbnailUrl']
                      : (data['postMediaUrl'] ?? data['postImageUrl']);
              final actualMediaUrl =
                  data['postMediaUrl'] ?? data['postImageUrl'];
              final heroTag = 'explore_post_${postDoc.id}';

              if (actualMediaUrl == null || actualMediaUrl.isEmpty) {
                return Container(color: cardColor);
              }

              return GestureDetector(
                onTap: () {
                  if (isVideo) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => FullScreenVideoPlayer(
                              videoUrl: actualMediaUrl,
                              postId: postDoc.id,
                            ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => FullScreenImageViewer(
                              imageUrl: actualMediaUrl,
                              heroTag: heroTag,
                              postId: postDoc.id,
                            ),
                      ),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background Image
                        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                          Hero(
                            tag: heroTag,
                            child: CachedNetworkImage(
                              imageUrl: thumbnailUrl,
                              fit: BoxFit.cover,
                              placeholder:
                                  (c, u) => Container(
                                    color:
                                        isDark
                                            ? Colors.white10
                                            : Colors.grey.shade200,
                                  ),
                              errorWidget:
                                  (c, u, e) => Container(
                                    color: cardColor,
                                    child: const Icon(
                                      Icons.error,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                          )
                        else
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF673AB7), Color(0xFF3F51B5)],
                              ),
                            ),
                          ),

                        // Dark Bottom Gradient for Stats
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.9),
                                  Colors.transparent,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.center,
                                stops: const [0.0, 0.4],
                              ),
                            ),
                          ),
                        ),

                        // Top Right Icons (Video / Carousel)
                        if (isVideo)
                          const Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 24,
                            ),
                          )
                        else if (isMultiImage)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.photo_library_outlined,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    imageCount.toString(),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Bottom Content (Title & Stats)
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.favorite,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    likesCount.toString(),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.chat_bubble,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    commentsCount.toString(),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }, childCount: visibleDocs.length),
          ),
        );
      },
    );
  }
}
