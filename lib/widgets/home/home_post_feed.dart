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
  final Color textColor;

  const HomePostFeed({super.key, required this.textColor});

  @override
  State<HomePostFeed> createState() => _HomePostFeedState();
}

class _HomePostFeedState extends State<HomePostFeed> {
  final User? user = FirebaseAuth.instance.currentUser;

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
      } on FirebaseException catch (e) {
        if (scaffoldMessenger.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Permission Denied or Error: ${e.message}')),
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
        // Remove the like
        await postRef.update({
          'likes': FieldValue.arrayRemove([user!.uid]),
        });
        // Explicitly delete notification on unlike to prevent stale duplicates
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notifId)
            .delete();
      } else {
        // Add the like
        await postRef.update({
          'likes': FieldValue.arrayUnion([user!.uid]),
        });

        // If someone else liked the post, send a notification
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
        if (userSnap.hasError) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                "Error loading profile data.\nCheck Firebase Rules.",
                textAlign: TextAlign.center,
                style: TextStyle(color: widget.textColor),
              ),
            ),
          );
        }

        if (!userSnap.hasData) {
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
            // Check for permission-denied errors explicitly
            if (snapshot.hasError) {
              final errorString = snapshot.error.toString();
              return SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 50,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Access Denied",
                          style: GoogleFonts.poppins(
                            color: widget.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          errorString.contains('permission-denied')
                              ? "Your Firebase Firestore rules are blocking read access. Please update your rules in the Firebase Console."
                              : "Error loading posts: $errorString",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      ],
                    ),
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
              }, childCount: visiblePosts.length),
            );
          },
        );
      },
    );
  }
}
