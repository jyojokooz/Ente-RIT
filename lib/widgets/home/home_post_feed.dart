// ===============================
// FILE NAME: home_post_feed.dart
// FILE PATH: lib/widgets/home/home_post_feed.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../screens/post_card.dart';
import '../../screens/post_card_placeholder.dart';
import '../../screens/comments_sheet.dart';
import '../../screens/edit_post_screen.dart';
import '../../screens/pages/profile_screen.dart';

class HomePostFeed extends StatefulWidget {
  final int selectedTab;
  final Color textColor;

  const HomePostFeed({
    super.key,
    required this.selectedTab,
    required this.textColor,
  });

  @override
  State<HomePostFeed> createState() => _HomePostFeedState();
}

class _HomePostFeedState extends State<HomePostFeed> {
  final user = FirebaseAuth.instance.currentUser!;

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
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        final userData = userDoc.data();
        final displayName = userData?['displayName'] ?? 'User';
        final profilePic = userData?['profilePhotoUrl'] ?? '';

        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': postAuthorId,
          'title': 'New Like',
          'body': '$displayName liked your post.',
          'type': 'like',
          'relatedDocId': postId,
          'triggeringUserId': user.uid,
          'triggeringUserName': displayName,
          'triggeringUserAvatarUrl': profilePic,
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
    // 1. Stream the CURRENT USER to get their latest connections
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final myData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
        final List<dynamic> myConnections = myData['connections'] ?? [];

        // 2. Stream the POSTS
        return StreamBuilder<QuerySnapshot>(
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
                    style: TextStyle(color: widget.textColor),
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

            // --- STRICT PRIVACY FILTER LOGIC ---
            List<DocumentSnapshot> visiblePosts =
                snapshot.data!.docs.where((postDoc) {
                  final data = postDoc.data() as Map<String, dynamic>;
                  final authorId = data['userId'];

                  // If the post lacks the 'isAuthorPrivate' field, it assumes false (public)
                  final isPrivate = data['isAuthorPrivate'] ?? false;

                  // 1. Always show my own posts
                  if (authorId == user.uid) return true;

                  // 2. If we are mingles (connections), always show their posts (even if private)
                  if (myConnections.contains(authorId)) return true;

                  // 3. If we are NOT mingles:
                  // Hide if the account is private
                  if (isPrivate) return false;

                  // Show only if the account is public
                  return true;
                }).toList();

            if (visiblePosts.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'No visible posts available.',
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }

            // Apply "Trending" sorting if the Trending tab is selected
            if (widget.selectedTab == 1) {
              visiblePosts.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aLikes = (aData['likes'] as List?)?.length ?? 0;
                final bLikes = (bData['likes'] as List?)?.length ?? 0;
                return bLikes.compareTo(aLikes);
              });
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final postSnapshot = visiblePosts[index];
                final postData = postSnapshot.data() as Map<String, dynamic>;

                return PostCard(
                  key: ValueKey(postSnapshot.id),
                  postSnapshot: postSnapshot,
                  onCommentPressed: () => _onCommentTapped(postSnapshot.id),
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
                      () =>
                          _editPost(postSnapshot.id, postData['caption'] ?? ''),
                );
              }, childCount: visiblePosts.length),
            );
          },
        );
      },
    );
  }
}
