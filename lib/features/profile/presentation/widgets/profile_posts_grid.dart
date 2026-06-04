// ===============================
// FILE NAME: profile_posts_grid.dart
// FILE PATH: lib/features/profile/presentation/widgets/profile_posts_grid.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// --- FIXED IMPORTS: Pointing to the new media_viewers connector ---
import 'package:my_project/core/widgets/media_viewers/media_viewers_connector.dart';

class ProfilePostsGrid extends StatelessWidget {
  final List<DocumentSnapshot> userPosts;
  final Color cardColor;
  final bool canViewPosts;
  final bool isTaggedTab;

  const ProfilePostsGrid({
    super.key,
    required this.userPosts,
    required this.cardColor,
    required this.canViewPosts,
    this.isTaggedTab = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!canViewPosts) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.white10 : Colors.black12,
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black26,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 50,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "This Account is Private",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Mingle with them to see their posts and photos.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (userPosts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(
                  isTaggedTab
                      ? Icons.loyalty_outlined
                      : Icons.camera_alt_outlined,
                  size: 40,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(height: 10),
                Text(
                  isTaggedTab ? "No tagged posts yet" : "No posts yet",
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // --- 2 COLUMN INSTAGRAM STYLE GRID WITH LABELS ---
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75, // Taller to fit text at the bottom
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final postSnapshot = userPosts[index];
          final data = postSnapshot.data() as Map<String, dynamic>;

          final isVideo = data['postType'] == 'video';

          // Thumbnail for Grid Display
          final thumbnailUrl =
              isVideo
                  ? data['postThumbnailUrl']
                  : (data['postMediaUrl'] ?? data['postImageUrl']);

          // Actual Media URL for Full Screen Playback/Viewing
          final actualMediaUrl = data['postMediaUrl'] ?? data['postImageUrl'];

          // Provide fallback values if empty
          final caption = data['caption']?.toString().trim() ?? '';
          final title = caption.isNotEmpty ? caption.split('\n').first : 'Post';

          final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
          final dateString =
              timestamp != null
                  ? DateFormat('d MMM yyyy').format(timestamp)
                  : '';

          // Check for multiple images
          int imageCount = 1;
          if (data['postImages'] != null) {
            imageCount = (data['postImages'] as List).length;
          }

          final heroTag = 'profile_post_${postSnapshot.id}';

          return GestureDetector(
            onTap: () {
              if (actualMediaUrl == null || actualMediaUrl.isEmpty) return;

              // --- DIRECT FULL SCREEN NAVIGATION ---
              if (isVideo) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => FullScreenVideoPlayer(
                          videoUrl: actualMediaUrl,
                          postId: postSnapshot.id,
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
                          postId: postSnapshot.id,
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
                    // Background Image (Wrapped in Hero for smooth opening transition)
                    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                      Hero(
                        tag: heroTag,
                        child: CachedNetworkImage(
                          imageUrl: thumbnailUrl,
                          fit: BoxFit.cover,
                          placeholder:
                              (c, u) => Container(
                                color: isDark ? Colors.white10 : Colors.black12,
                              ),
                          errorWidget:
                              (c, u, e) => Container(
                                color: cardColor,
                                child: const Icon(
                                  Icons.broken_image,
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

                    // Dark Bottom Gradient for Text Readability
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.black.withOpacity(0.9),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.4],
                          ),
                        ),
                      ),
                    ),

                    // Video or Multi-image Indicator (Top Right)
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
                    else if (imageCount > 1)
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

                    // Title and Date (Bottom Left)
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
                          if (dateString.isNotEmpty)
                            Text(
                              dateString,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }, childCount: userPosts.length),
      ),
    );
  }
}
