// ===============================
// FILE NAME: profile_posts_grid.dart
// FILE PATH: lib/widgets/profile/profile_posts_grid.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

// --- REMOVE PostDetailScreen import and REPLACE with ProfileFeedScreen ---
import '../../screens/profile_feed_screen.dart';

class ProfilePostsGrid extends StatelessWidget {
  final List<DocumentSnapshot> userPosts;
  final Color cardColor;
  final bool canViewPosts;

  const ProfilePostsGrid({
    super.key,
    required this.userPosts,
    required this.cardColor,
    required this.canViewPosts,
  });

  @override
  Widget build(BuildContext context) {
    // --- PRIVATE ACCOUNT UI ---
    if (!canViewPosts) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
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

    // --- NO POSTS UI ---
    if (userPosts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 40,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(height: 10),
                Text(
                  "No posts yet",
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // --- NORMAL GRID UI ---
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final postSnapshot = userPosts[index];
          final data = postSnapshot.data() as Map<String, dynamic>;
          final mediaUrl =
              data['postType'] == 'video'
                  ? data['postThumbnailUrl']
                  : (data['postMediaUrl'] ?? data['postImageUrl']);

          return GestureDetector(
            // --- UPDATED TAP LOGIC ---
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ProfileFeedScreen(
                          posts: userPosts,
                          initialIndex: index,
                        ),
                  ),
                ),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (mediaUrl != null)
                      CachedNetworkImage(
                        imageUrl: mediaUrl,
                        fit: BoxFit.cover,
                        placeholder:
                            (c, u) =>
                                Container(color: Colors.grey.withOpacity(0.1)),
                        errorWidget: (c, u, e) => const Icon(Icons.error),
                      )
                    else
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF3E8E), Color(0xFFFF9A44)],
                          ),
                        ),
                      ),
                    if (data['postType'] == 'video')
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 24,
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
