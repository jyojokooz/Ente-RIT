// ===============================
// FILE NAME: explore_screen.dart
// FILE PATH: C:\Ente-RITEEE\Ente-RIT\lib\features\explore\presentation\explore_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:my_project/features/explore/presentation/search_screen.dart';
import 'package:my_project/features/profile/presentation/requests_screen.dart';
import 'package:my_project/features/profile/presentation/find_friends_screen.dart';
import 'package:my_project/features/posts/presentation/widgets/post_card.dart';
import 'package:my_project/features/posts/presentation/widgets/comments_sheet.dart';
import 'package:my_project/features/posts/presentation/edit_post_screen.dart';
import 'package:my_project/features/profile/presentation/profile_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // --- POST ACTION METHODS ---
  Future<void> _toggleLike(
    String postId,
    bool isLikedNow,
    String postAuthorId,
  ) async {
    if (user == null) return;
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    final notifId = 'like_${postId}_${user!.uid}';

    try {
      if (!isLikedNow) {
        await postRef.update({
          'likes': FieldValue.arrayRemove([user!.uid]),
        });
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notifId)
            .delete();
      } else {
        await postRef.update({
          'likes': FieldValue.arrayUnion([user!.uid]),
        });
        if (postAuthorId != user!.uid) {
          final userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .get();
          final userData = userDoc.data();

          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(notifId)
              .set({
                'userId': postAuthorId,
                'title': 'New Like',
                'body':
                    '${userData?['displayName'] ?? 'User'} liked your post.',
                'type': 'like',
                'relatedDocId': postId,
                'triggeringUserId': user!.uid,
                'triggeringUserName': userData?['displayName'] ?? 'User',
                'triggeringUserAvatarUrl': userData?['profilePhotoUrl'] ?? '',
                'isRead': false,
                'timestamp': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint("Toggle like error: $e");
    }
  }

  Future<void> _deletePost(String postId) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bool? didRequestDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF252528) : Colors.white,
          title: Text(
            'Delete Post?',
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to permanently remove this post?',
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
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
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Post deleted.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  void _editPost(
    String postId,
    String currentCaption,
    List<String> currentTags,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditPostScreen(
              postId: postId,
              initialCaption: currentCaption,
              initialTaggedUsers: currentTags,
            ),
      ),
    );
  }

  void _onCommentTapped(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: CommentsSheet(postId: postId),
          ),
    );
  }

  void _onProfileTapped(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen(userId: userId)),
    );
  }

  // --- SHOW POST IN MODAL BOTTOM SHEET ---
  void _openPostModal(DocumentSnapshot postDoc) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          PostCard(
                            postSnapshot: postDoc,
                            onCommentPressed:
                                () => _onCommentTapped(postDoc.id),
                            onDeletePressed: () {
                              Navigator.pop(ctx); // Close modal first
                              _deletePost(postDoc.id);
                            },
                            onProfileTapped: () {
                              Navigator.pop(ctx);
                              _onProfileTapped(postDoc.get('userId'));
                            },
                            onLikePressed:
                                (isLikedNow) => _toggleLike(
                                  postDoc.id,
                                  isLikedNow,
                                  postDoc.get('userId'),
                                ),
                            onEditPressed: () {
                              Navigator.pop(ctx);
                              _editPost(
                                postDoc.id,
                                postDoc.get('caption') ?? '',
                                List<String>.from(
                                  postDoc.get('taggedUsers') ?? [],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 40), // Bottom padding
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                    iconBgColor: const Color(0xFFB165FF),
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
                    iconBgColor: const Color(0xFF00C6FB),
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

          // --- 2. TRENDING POSTS GRID ---
          if (user == null)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .snapshots(),
              builder: (context, userSnap) {
                if (!userSnap.hasData)
                  return const SliverToBoxAdapter(child: SizedBox.shrink());

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
                                style: GoogleFonts.poppins(
                                  color: subtitleColor,
                                ),
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
                          if (authorId == user!.uid) return true;
                          if (!isPrivate) return true;
                          return myConnections.contains(authorId);
                        }).toList();

                    visibleDocs.sort((a, b) {
                      final aLikes =
                          ((a.data() as Map<String, dynamic>)['likes']
                                      as List<dynamic>? ??
                                  [])
                              .length;
                      final bLikes =
                          ((b.data() as Map<String, dynamic>)['likes']
                                      as List<dynamic>? ??
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
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                              childAspectRatio: 1.0,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final postDoc = visibleDocs[index];
                          final data = postDoc.data() as Map<String, dynamic>;
                          final likesCount =
                              (data['likes'] as List<dynamic>? ?? []).length;
                          final commentsCount = data['comments'] ?? 0;
                          final isVideo = data['postType'] == 'video';
                          final imagesList =
                              data['postImages'] as List<dynamic>? ?? [];
                          final isMultiImage = imagesList.length > 1;

                          final mediaUrl =
                              isVideo
                                  ? data['postThumbnailUrl']
                                  : (data['postMediaUrl'] ??
                                      data['postImageUrl']);

                          if (mediaUrl == null || mediaUrl.isEmpty) {
                            return Container(color: cardColor);
                          }

                          return GestureDetector(
                            onTap: () => _openPostModal(postDoc),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
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

                                  // Dark Bottom Gradient for Stats
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    height: 50,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.black.withOpacity(0.8),
                                            Colors.transparent,
                                          ],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Top Right Icons (Video / Carousel)
                                  if (isVideo)
                                    const Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Icon(
                                        Icons.play_circle_fill,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    )
                                  else if (isMultiImage)
                                    const Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Icon(
                                        Icons.collections_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),

                                  // Bottom Left Stats
                                  Positioned(
                                    bottom: 6,
                                    left: 6,
                                    child: Row(
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
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
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
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
