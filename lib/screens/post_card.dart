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

  const PostCard({
    super.key,
    required this.postSnapshot,
    required this.onCommentPressed,
    required this.onDeletePressed,
    required this.onProfileTapped,
    required this.onLikePressed,
  });

  @override
  Widget build(BuildContext context) {
    final postData = postSnapshot.data() as Map<String, dynamic>;
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final Color cardBackgroundColor = Colors.grey.shade900;
    const Color primaryTextColor = Colors.white;

    // --- START: THE FIX FOR BACKWARD COMPATIBILITY ---
    // First, try to get the new 'postMediaUrl'. If it's null (for old posts),
    // then try to get the old 'postImageUrl'. If both are null, default to empty.
    final String mediaUrl =
        postData['postMediaUrl'] ?? postData['postImageUrl'] ?? '';
    // --- END: THE FIX FOR BACKWARD COMPATIBILITY ---

    final String postType =
        postData['postType'] ?? 'image'; // Default old posts to 'image'
    final String? thumbnailUrl = postData['postThumbnailUrl'];
    final String caption = postData['caption'] ?? '';
    final bool isAuthor = postData['userId'] == currentUserId;
    final timestamp = (postData['timestamp'] as Timestamp?)?.toDate();
    final String postAuthorId = postData['userId'];
    final String heroTag = 'postImage-${postSnapshot.id}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(25.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostHeader(
              context: context,
              postAuthorId: postAuthorId,
              timestamp: timestamp,
              isAuthor: isAuthor,
              onProfileTapped: onProfileTapped,
              onDeletePressed: onDeletePressed,
            ),
            if (caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  caption,
                  style: GoogleFonts.poppins(
                    color: primaryTextColor.withAlpha(220),
                  ),
                ),
              ),
            if (mediaUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child:
                    (postType == 'video')
                        ? _buildVideoPlayer(context, mediaUrl, thumbnailUrl)
                        : _buildImageViewer(context, mediaUrl, heroTag),
              ),
            const SizedBox(height: 12),
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postSnapshot.id)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 24);
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const SizedBox.shrink();
                }
                final realTimePostData =
                    snapshot.data!.data() as Map<String, dynamic>;
                final List<dynamic> likesList = realTimePostData['likes'] ?? [];
                final int commentCount = realTimePostData['comments'] ?? 0;
                final bool isLiked = likesList.contains(currentUserId);
                final int likeCount = likesList.length;
                return _buildActionButtons(
                  context,
                  isLiked: isLiked,
                  likeCount: likeCount,
                  commentCount: commentCount,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(
    BuildContext context,
    String videoUrl,
    String? thumbnailUrl,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenVideoPlayer(videoUrl: videoUrl),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: Image.network(
              thumbnailUrl ??
                  'https://via.placeholder.com/300/000000/FFFFFF/?text=Video',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 300,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 300,
                  color: Colors.grey.shade800,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.yellow),
                  ),
                );
              },
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    height: 300,
                    color: Colors.grey.shade800,
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 80.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageViewer(
    BuildContext context,
    String imageUrl,
    String heroTag,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    FullScreenImageViewer(imageUrl: imageUrl, heroTag: heroTag),
          ),
        );
      },
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 300,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 300,
                color: Colors.grey.shade800,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.yellow),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPostHeader({
    required BuildContext context,
    required String postAuthorId,
    required DateTime? timestamp,
    required bool isAuthor,
    required VoidCallback onProfileTapped,
    required VoidCallback onDeletePressed,
  }) {
    const Color primaryTextColor = Colors.white;
    const Color secondaryTextColor = Colors.white70;

    final String formattedDate =
        timestamp != null
            ? DateFormat('MMM d, h:mm a').format(timestamp)
            : '...';

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(postAuthorId)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Row(
            children: [
              const CircleAvatar(radius: 20, backgroundColor: Colors.grey),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 120,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 12,
                      width: 80,
                      color: Colors.grey.shade700,
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final String name = userData['displayName'] ?? 'Unknown User';
        final String username = userData['username'] ?? '';
        final String userImage = userData['profilePhotoUrl'] ?? '';

        return GestureDetector(
          onTap: onProfileTapped,
          child: Container(
            color: Colors.transparent,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      userImage.isNotEmpty ? NetworkImage(userImage) : null,
                  child: userImage.isEmpty ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      if (username.isNotEmpty)
                        Text(
                          '@$username',
                          style: GoogleFonts.poppins(
                            color: secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  formattedDate,
                  style: GoogleFonts.poppins(
                    color: secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
                if (isAuthor) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.more_horiz,
                      color: secondaryTextColor,
                    ),
                    onPressed: onDeletePressed,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(
    BuildContext context, {
    required bool isLiked,
    required int likeCount,
    required int commentCount,
  }) {
    const Color primaryAccentColor = Colors.yellow;
    const Color secondaryTextColor = Colors.white70;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onCommentPressed,
              child: Container(
                color: Colors.transparent,
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 22,
                      color: secondaryTextColor,
                    ),
                    if (commentCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: Text(
                          commentCount.toString(),
                          style: const TextStyle(color: secondaryTextColor),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(0),
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? primaryAccentColor : secondaryTextColor,
              ),
              iconSize: 24,
              onPressed: onLikePressed,
            ),
            if (likeCount > 0)
              Padding(
                padding: const EdgeInsets.only(left: 2.0),
                child: Text(
                  likeCount.toString(),
                  style: const TextStyle(color: secondaryTextColor),
                ),
              ),
          ],
        ),
        const Row(
          children: [
            Icon(Icons.send_outlined, size: 22, color: secondaryTextColor),
          ],
        ),
      ],
    );
  }
}
