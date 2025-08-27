import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'full_screen_image_viewer.dart'; // Make sure this import is correct

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

    // --- Data that belongs to the post itself ---
    final String postImage = postData['postImageUrl'] ?? '';
    final String caption = postData['caption'] ?? '';
    final List<dynamic> likesList = postData['likes'] ?? [];
    final bool isLiked = likesList.contains(currentUserId);
    final int likeCount = likesList.length;
    final int commentCount = postData['comments'] ?? 0;
    final bool isAuthor = postData['userId'] == currentUserId;
    final timestamp = (postData['timestamp'] as Timestamp?)?.toDate();

    // --- Post Author ID ---
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
            // --- FIX: This header now fetches live user data ---
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
            if (postImage.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => FullScreenImageViewer(
                            imageUrl: postImage,
                            heroTag: heroTag,
                          ),
                    ),
                  );
                },
                child: Hero(
                  tag: heroTag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: Image.network(
                      postImage,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 300,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 300,
                          color: Colors.grey.shade800,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.yellow,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            _buildActionButtons(
              context,
              isLiked: isLiked,
              likeCount: likeCount,
              commentCount: commentCount,
            ),
          ],
        ),
      ),
    );
  }

  /// A helper widget that builds the post header using a StreamBuilder
  /// to get real-time user data (name, username, profile picture).
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
      // Listen to the specific user's document
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(postAuthorId)
              .snapshots(),
      builder: (context, snapshot) {
        // --- Loading State ---
        if (!snapshot.hasData) {
          // Show a placeholder while data is loading
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

        // --- Data Loaded State ---
        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final String name =
            userData['displayName'] ?? 'Unknown User'; // Use displayName
        final String username = userData['username'] ?? '';
        final String userImage =
            userData['profilePhotoUrl'] ?? ''; // Use profilePhotoUrl

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

  /// A helper widget for the action buttons (like, comment, share)
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
