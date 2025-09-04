import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import 'full_screen_image_viewer.dart';
import 'full_screen_video_player.dart';
import 'post_card_placeholder.dart';

class PostCard extends StatefulWidget {
  final DocumentSnapshot postSnapshot;
  final Function() onCommentPressed;
  final Function() onDeletePressed;
  final Function() onProfileTapped;
  final Function() onLikePressed;
  final Function() onEditPressed;

  const PostCard({
    super.key,
    required this.postSnapshot,
    required this.onCommentPressed,
    required this.onDeletePressed,
    required this.onProfileTapped,
    required this.onLikePressed,
    required this.onEditPressed,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  Map<String, dynamic>? _authorData;
  bool _isLoadingAuthor = true;

  @override
  void initState() {
    super.initState();
    _fetchAuthorData();
  }

  Future<void> _fetchAuthorData() async {
    try {
      final postData = widget.postSnapshot.data() as Map<String, dynamic>;
      final authorId = postData['userId'];
      if (authorId == null || authorId.isEmpty) {
        throw Exception("Author ID is missing");
      }
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(authorId)
              .get();

      if (mounted) {
        setState(() {
          _authorData = userDoc.data();
          _isLoadingAuthor = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAuthor = false;
          _authorData = {'displayName': 'Unknown User', 'username': ''};
        });
      }
    }
  }

  String getOptimizedCloudinaryUrl(String originalUrl) {
    if (!originalUrl.contains('res.cloudinary.com')) {
      return originalUrl;
    }
    const transformations = 'w_600,q_auto,f_auto';
    final parts = originalUrl.split('/upload/');
    if (parts.length == 2) {
      return '${parts[0]}/upload/$transformations/${parts[1]}';
    }
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAuthor) {
      return const PostCardPlaceholder();
    }

    final postData = widget.postSnapshot.data() as Map<String, dynamic>;
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final Color cardBackgroundColor = Colors.grey.shade900;
    const Color primaryTextColor = Colors.white;

    final String originalMediaUrl =
        postData['postMediaUrl'] ?? postData['postImageUrl'] ?? '';
    final String? originalThumbnailUrl = postData['postThumbnailUrl'];

    final String postType = postData['postType'] ?? 'image';
    final String caption = postData['caption'] ?? '';
    final bool isAuthor = postData['userId'] == currentUserId;
    final timestamp = (postData['timestamp'] as Timestamp?)?.toDate();
    final String heroTag = 'postImage-${widget.postSnapshot.id}';

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
              authorData: _authorData,
              timestamp: timestamp,
              isAuthor: isAuthor,
              onProfileTapped: widget.onProfileTapped,
              onDeletePressed: widget.onDeletePressed,
              onEditPressed: widget.onEditPressed,
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
            if (originalMediaUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child:
                    (postType == 'video')
                        ? _buildVideoPlayer(
                          context,
                          originalMediaUrl,
                          originalThumbnailUrl,
                        )
                        : _buildImageViewer(context, originalMediaUrl, heroTag),
              ),
            const SizedBox(height: 12),
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postSnapshot.id)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  final likesList = postData['likes'] ?? [];
                  return _buildActionButtons(
                    context,
                    isLiked: likesList.contains(currentUserId),
                    likeCount: likesList.length,
                    commentCount: postData['comments'] ?? 0,
                  );
                }
                final realTimeData =
                    snapshot.data!.data() as Map<String, dynamic>;
                final rtLikes = realTimeData['likes'] ?? [];
                return _buildActionButtons(
                  context,
                  isLiked: rtLikes.contains(currentUserId),
                  likeCount: rtLikes.length,
                  commentCount: realTimeData['comments'] ?? 0,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageViewer(
    BuildContext context,
    String originalImageUrl,
    String heroTag,
  ) {
    final String optimizedUrl = getOptimizedCloudinaryUrl(originalImageUrl);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => FullScreenImageViewer(
                  imageUrl: originalImageUrl,
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
            optimizedUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 300,
            loadingBuilder: (context, child, progress) {
              if (progress == null) {
                return child;
              }
              return Shimmer.fromColors(
                baseColor: Colors.grey.shade800,
                highlightColor: Colors.grey.shade700,
                child: Container(
                  height: 300,
                  width: double.infinity,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder:
                (context, error, stackTrace) => Container(
                  height: 300,
                  color: Colors.grey.shade800,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(
    BuildContext context,
    String originalVideoUrl,
    String? originalThumbnailUrl,
  ) {
    final String optimizedThumbnailUrl =
        originalThumbnailUrl != null
            ? getOptimizedCloudinaryUrl(originalThumbnailUrl)
            : 'https://via.placeholder.com/600x600/000000/FFFFFF/?text=Video';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => FullScreenVideoPlayer(videoUrl: originalVideoUrl),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: Image.network(
              optimizedThumbnailUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 300,
              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return child;
                }
                return Shimmer.fromColors(
                  baseColor: Colors.grey.shade800,
                  highlightColor: Colors.grey.shade700,
                  child: Container(height: 300, color: Colors.white),
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

  Widget _buildPostHeader({
    required BuildContext context,
    required Map<String, dynamic>? authorData,
    required DateTime? timestamp,
    required bool isAuthor,
    required VoidCallback onProfileTapped,
    required VoidCallback onDeletePressed,
    required VoidCallback onEditPressed,
  }) {
    const Color primaryTextColor = Colors.white;
    const Color secondaryTextColor = Colors.white70;

    final String formattedDate =
        timestamp != null
            ? DateFormat('MMM d, h:mm a').format(timestamp)
            : '...';

    final userData = authorData ?? {};
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            if (isAuthor)
              PopupMenuButton<String>(
                onSelected: (value) {
                  // --- THIS IS THE FIX ---
                  // Wrapped the single-line statements in curly braces.
                  if (value == 'edit') {
                    onEditPressed();
                  } else if (value == 'delete') {
                    onDeletePressed();
                  }
                },
                itemBuilder:
                    (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Edit Post'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text(
                          'Delete Post',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                color: Colors.grey.shade800,
                icon: const Icon(Icons.more_horiz, color: secondaryTextColor),
              ),
          ],
        ),
      ),
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
              onTap: widget.onCommentPressed,
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
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
            GestureDetector(
              onTap: widget.onLikePressed,
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? primaryAccentColor : secondaryTextColor,
                      size: 24,
                    ),
                    if (likeCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: Text(
                          likeCount.toString(),
                          style: const TextStyle(color: secondaryTextColor),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.send_outlined,
            size: 22,
            color: secondaryTextColor,
          ),
        ),
      ],
    );
  }
}
