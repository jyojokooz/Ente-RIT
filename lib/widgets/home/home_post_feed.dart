// ===============================
// FILE NAME: home_post_feed.dart
// FILE PATH: lib/widgets/home/home_post_feed.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../screens/post_card.dart';
import '../../screens/comments_sheet.dart';
import '../../screens/edit_post_screen.dart';
import '../../screens/pages/profile_screen.dart';

class HomePostFeed extends StatefulWidget {
  final Color textColor;

  const HomePostFeed({super.key, required this.textColor});

  @override
  State<HomePostFeed> createState() => _HomePostFeedState();
}

class _HomePostFeedState extends State<HomePostFeed> {
  final User? user = FirebaseAuth.instance.currentUser;

  // Track the active feed tab
  String _activeTab = 'For You';
  final List<String> _tabs = ['For You', 'Following', 'Popular'];

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
              color: theme.colorScheme.onSurface.withAlpha(178),
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
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Text('Post deleted.'),
              backgroundColor: theme.colorScheme.onSurface,
            ),
          );
        }
      } catch (e) {
        if (scaffoldMessenger.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

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
          final displayName = userData?['displayName'] ?? 'User';
          final profilePic = userData?['profilePhotoUrl'] ?? '';

          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(notifId)
              .set({
                'userId': postAuthorId,
                'title': 'New Like',
                'body': '$displayName liked your post.',
                'type': 'like',
                'relatedDocId': postId,
                'triggeringUserId': user!.uid,
                'triggeringUserName': displayName,
                'triggeringUserAvatarUrl': profilePic,
                'isRead': false,
                'timestamp': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint("Toggle like error: $e");
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

  // --- BUILD TABS UI ---
  Widget _buildTabsHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 20),
      child: Row(
        children:
            _tabs.map((tab) {
              final isActive = _activeTab == tab;
              return GestureDetector(
                onTap: () => setState(() => _activeTab = tab),
                child: Padding(
                  padding: const EdgeInsets.only(right: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        tab,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.w500,
                          color:
                              isActive
                                  ? (isDark ? Colors.white : Colors.black)
                                  : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Animated underline
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 3,
                        width: isActive ? 24 : 0,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9983F3), // Purple Accent
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            "Please log in to view posts.",
            style: TextStyle(color: widget.textColor),
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .snapshots(),
      builder: (context, userSnap) {
        if (userSnap.hasError || !userSnap.hasData) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final myData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
        final List<dynamic> myConnections = myData['connections'] ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      "Error loading posts.",
                      style: TextStyle(color: widget.textColor),
                    ),
                  ),
                ),
              );
            }

            // --- THE FIX IS HERE ---
            // Removed the giant Shimmer block and replaced it with a tiny spinner
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) return _buildTabsHeader();
                    // Small loading spinner below the navbar
                    return const Padding(
                      padding: EdgeInsets.only(top: 40.0),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF9983F3), // Purple Accent
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: 2, // 1 for the Tab Header, 1 for the Spinner
                ),
              );
            }

            // 1. Initial Filtering (Privacy Check)
            List<DocumentSnapshot> visiblePosts =
                snapshot.data!.docs.where((postDoc) {
                  final data = postDoc.data() as Map<String, dynamic>;
                  final authorId = data['userId'];
                  final isPrivate = data['isAuthorPrivate'] ?? false;

                  if (authorId == user!.uid) return true;
                  if (myConnections.contains(authorId)) return true;
                  if (isPrivate) return false;
                  return true;
                }).toList();

            // 2. Tab Logic (Filtering & Sorting)
            if (_activeTab == 'Following') {
              visiblePosts =
                  visiblePosts.where((doc) {
                    final authorId =
                        (doc.data() as Map<String, dynamic>)['userId'];
                    return myConnections.contains(authorId) ||
                        authorId == user!.uid;
                  }).toList();
            } else if (_activeTab == 'Popular') {
              visiblePosts.sort((a, b) {
                final aLikes =
                    ((a.data() as Map<String, dynamic>)['likes'] as List?)
                        ?.length ??
                    0;
                final bLikes =
                    ((b.data() as Map<String, dynamic>)['likes'] as List?)
                        ?.length ??
                    0;
                return bLikes.compareTo(aLikes); // Descending order
              });
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Render tabs at the very top of the list
                  if (index == 0) return _buildTabsHeader();

                  final postIndex =
                      index - 1; // Adjust index since 0 is the tabs

                  if (visiblePosts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          'No posts found for this filter.',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  if (postIndex >= visiblePosts.length)
                    return const SizedBox.shrink();

                  final postSnapshot = visiblePosts[postIndex];
                  final postData = postSnapshot.data() as Map<String, dynamic>;

                  return PostCard(
                    key: ValueKey(postSnapshot.id),
                    postSnapshot: postSnapshot,
                    onCommentPressed: () => _onCommentTapped(postSnapshot.id),
                    onDeletePressed: () => _deletePost(postSnapshot.id),
                    onProfileTapped:
                        () => _onProfileTapped(postData['userId'] ?? ''),
                    onLikePressed:
                        (bool isLikedNow) => _toggleLike(
                          postSnapshot.id,
                          isLikedNow,
                          postData['userId'] ?? '',
                        ),
                    onEditPressed:
                        () => _editPost(
                          postSnapshot.id,
                          postData['caption'] ?? '',
                          List<String>.from(postData['taggedUsers'] ?? []),
                        ),
                  );
                },
                childCount: visiblePosts.isEmpty ? 2 : visiblePosts.length + 1,
              ), // +1 for the Tab Header
            );
          },
        );
      },
    );
  }
}
