// ===============================
// FILE NAME: explore_screen.dart
// FILE PATH: lib/screens/pages/explore_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../search_screen.dart';
import '../requests_screen.dart';
import '../post_detail_screen.dart';
import '../find_friends_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // UPDATED: Now matches Profile Screen's background color
    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Explore',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 24,
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- 1. SEARCH BAR & HEADER ACTIONS ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Search Bar
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchScreen(),
                        ),
                      );
                    },
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: subtitleColor),
                          const SizedBox(width: 12),
                          Text(
                            'Search for users...',
                            style: GoogleFonts.poppins(
                              color: subtitleColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // FIND FRIENDS / SUGGESTIONS SECTION
                  _buildMenuTile(
                    context: context,
                    icon: Icons.people_alt_outlined,
                    iconColor: Colors.white,
                    iconBgColor: const Color(0xFFB165FF), // Purple
                    title: "Find Friends",
                    subtitle: "Connect with people you may know",
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    cardColor: cardColor,
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FindFriendsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.person_add_alt_1_outlined,
                    iconColor: Colors.white,
                    iconBgColor: const Color(0xFF00C6FB), // Light Blue
                    title: "Connection Requests",
                    subtitle: "View pending requests",
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    cardColor: cardColor,
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RequestsScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // TRENDING HEADER
                  Text(
                    'Trending Posts',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // --- 2. TRENDING POSTS GRID WITH PRIVACY FILTER ---
          StreamBuilder<DocumentSnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
            builder: (context, userSnap) {
              if (!userSnap.hasData) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF3E8E)),
                  ),
                );
              }

              final myData =
                  userSnap.data!.data() as Map<String, dynamic>? ?? {};
              final List<dynamic> myConnections = myData['connections'] ?? [];

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
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF3E8E),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          "Error loading trending posts",
                          style: TextStyle(color: subtitleColor),
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

                  // --- FILTER OUT PRIVATE STRANGER POSTS ---
                  final visibleDocs =
                      snapshot.data!.docs.where((postDoc) {
                        final data = postDoc.data() as Map<String, dynamic>;
                        final authorId = data['userId'];
                        final isPrivate = data['isAuthorPrivate'] ?? false;

                        // Always see your own posts
                        if (authorId == FirebaseAuth.instance.currentUser!.uid)
                          return true;
                        // Always see public posts
                        if (!isPrivate) return true;
                        // See private posts ONLY if connected
                        return myConnections.contains(authorId);
                      }).toList();

                  // Sort remaining visible posts by the number of likes (descending)
                  visibleDocs.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;

                    final aLikes =
                        (aData['likes'] as List<dynamic>? ?? []).length;
                    final bLikes =
                        (bData['likes'] as List<dynamic>? ?? []).length;

                    return bLikes.compareTo(aLikes); // Descending order
                  });

                  if (visibleDocs.isEmpty) {
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
                              'No trending posts available.',
                              style: GoogleFonts.poppins(color: subtitleColor),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.only(bottom: 80),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                            childAspectRatio: 1.0,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final postDoc = visibleDocs[index];
                        final data = postDoc.data() as Map<String, dynamic>;
                        final likesCount =
                            (data['likes'] as List<dynamic>? ?? []).length;

                        // Extract image or video thumbnail
                        final mediaUrl =
                            data['postType'] == 'video'
                                ? data['postThumbnailUrl']
                                : (data['postMediaUrl'] ??
                                    data['postImageUrl']);

                        if (mediaUrl == null || mediaUrl.isEmpty) {
                          return Container(color: cardColor);
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        PostDetailScreen(postId: postDoc.id),
                              ),
                            );
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: mediaUrl,
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

                              // Video Icon overlay
                              if (data['postType'] == 'video')
                                const Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),

                              // Like Count overlay
                              Positioned(
                                bottom: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
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
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }, childCount: visibleDocs.length),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subtitleColor,
    required Color cardColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: subtitleColor,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: subtitleColor, size: 20),
          ],
        ),
      ),
    );
  }
}
