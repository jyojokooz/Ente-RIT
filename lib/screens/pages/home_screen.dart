// ===============================
// FILE NAME: home_screen.dart
// FILE PATH: lib/screens/pages/home_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../comments_sheet.dart';
import '../edit_post_screen.dart';
import '../notifications_screen.dart';
import '../chat_list_screen.dart';
import '../post_card.dart';
import '../post_card_placeholder.dart';
import '../create_post_screen.dart';
import 'profile_screen.dart';
import '../../widgets/notification_badge.dart';
import '../../widgets/stories_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  String _displayName = '';
  String _profilePic = '';
  int _selectedTab = 0; // 0: Recent, 1: Trending

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (doc.exists && mounted) {
      setState(() {
        _displayName = doc.data()?['displayName'] ?? 'User';
        _profilePic = doc.data()?['profilePhotoUrl'] ?? '';
      });
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Route _createSmoothRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
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

  Future<void> _deletePost(String postId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    final bool? didRequestDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            'Delete Post?',
            style: GoogleFonts.poppins(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to permanently remove this post?',
            style: GoogleFonts.poppins(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
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
        if (mounted)
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Text('Post deleted.'),
              backgroundColor: theme.colorScheme.onSurface,
            ),
          );
      } catch (e) {
        if (scaffoldMessenger.mounted)
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
      }
    }
  }

  Future<void> _toggleLike(
    String postId,
    List<dynamic> currentLikes,
    String postAuthorId,
  ) async {
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
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
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': postAuthorId,
          'title': 'New Like',
          'body': '$_displayName liked your post.',
          'type': 'like',
          'relatedDocId': postId,
          'triggeringUserId': user.uid,
          'triggeringUserName': _displayName,
          'triggeringUserAvatarUrl': _profilePic,
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Custom colors matching the design
    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        color: const Color(0xFFFF3E8E),
        backgroundColor: cardColor,
        child: SafeArea(
          child: CustomScrollView(
            cacheExtent: 1000,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. TOP APP BAR & GREETING
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ente RIT',
                            style: GoogleFonts.satisfy(
                              // Stylish font for logo
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          // --- UPDATED TOP RIGHT BUTTONS ---
                          Row(
                            children: [
                              NotificationBadge(
                                child: _buildTopBarButton(
                                  icon:
                                      Icons
                                          .notifications_none_rounded, // Replaced Heart with Bell
                                  onTap:
                                      () => Navigator.push(
                                        context,
                                        _createSmoothRoute(
                                          const NotificationsScreen(),
                                        ),
                                      ),
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              _buildTopBarButton(
                                icon:
                                    Icons
                                        .maps_ugc_rounded, // Modern message/forum icon instead of plain chat bubble
                                onTap:
                                    () => Navigator.push(
                                      context,
                                      _createSmoothRoute(
                                        const ChatListScreen(),
                                      ),
                                    ),
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Hello ${_displayName.split(' ').first}! 👋',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "What's bothering you?",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. FAKE INPUT BOX
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: cardColor,
                        backgroundImage:
                            _profilePic.isNotEmpty
                                ? CachedNetworkImageProvider(_profilePic)
                                : null,
                        child:
                            _profilePic.isEmpty
                                ? Icon(
                                  Icons.person,
                                  color: isDark ? Colors.white54 : Colors.grey,
                                )
                                : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap:
                              () => Navigator.push(
                                context,
                                _createSmoothRoute(const CreatePostScreen()),
                              ),
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Share anything you want.",
                              style: GoogleFonts.poppins(
                                color: isDark ? Colors.white54 : Colors.black45,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. STORIES BAR
              const SliverToBoxAdapter(child: StoriesBar()),

              // 4. SEGMENTED TABS
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildTab("Recent", 0, isDark),
                        _buildTab("Trending", 1, isDark),
                      ],
                    ),
                  ),
                ),
              ),

              // 5. POST FEED
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('posts')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          "Error loading posts",
                          style: TextStyle(color: textColor),
                        ),
                      ),
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
                        child: Text(
                          'No posts yet.',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
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
                      return PostCard(
                        key: ValueKey(postSnapshot.id),
                        postSnapshot: postSnapshot,
                        onCommentPressed:
                            () => _onCommentTapped(postSnapshot.id),
                        onDeletePressed: () => _deletePost(postSnapshot.id),
                        onProfileTapped:
                            () => _onProfileTapped(postData['userId'] ?? ''),
                        onLikePressed:
                            () => _toggleLike(
                              postSnapshot.id,
                              postData['likes'] ?? [],
                              postData['userId'] ?? '',
                            ),
                        onEditPressed:
                            () => _editPost(
                              postSnapshot.id,
                              postData['caption'] ?? '',
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
    );
  }

  // --- NEW: Helper method to build the stylized top bar buttons ---
  Widget _buildTopBarButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF252528) : Colors.white,
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
            width: 1.5,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : Colors.black87,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index, bool isDark) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            gradient:
                isSelected
                    ? const LinearGradient(
                      colors: [Color(0xFFB165FF), Color(0xFFFF4B72)],
                    ) // Purple to Pink
                    : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color:
                  isSelected
                      ? Colors.white
                      : (isDark ? Colors.white54 : Colors.black54),
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
