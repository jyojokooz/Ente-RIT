// ===============================
// FILE NAME: post_card.dart
// FILE PATH: lib/screens/post_card.dart
// ===============================

// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart'; // Ensure shimmer is in pubspec.yaml

import 'full_screen_image_viewer.dart';
import 'full_screen_video_player.dart';
import 'share_post_sheet.dart';

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

class _PostCardState extends State<PostCard>
    with AutomaticKeepAliveClientMixin {
  int _currentImageIndex = 0;

  @override
  bool get wantKeepAlive => true;

  String getOptimizedCloudinaryUrl(String originalUrl) {
    if (!originalUrl.contains('res.cloudinary.com')) return originalUrl;
    const transformations = 'w_1080,q_auto:good,f_auto';
    final parts = originalUrl.split('/upload/');
    if (parts.length == 2)
      return '${parts[0]}/upload/$transformations/${parts[1]}';
    return originalUrl;
  }

  void _onSharePressed(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SharePostSheet(postId: widget.postSnapshot.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final postData = widget.postSnapshot.data() as Map<String, dynamic>?;
    if (postData == null) return const SizedBox.shrink();

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    const Color brandBlack = Colors.black;

    final authorData = {
      'displayName': postData['userName'] ?? 'Unknown',
      'username': postData['username'] ?? '',
      'profilePhotoUrl': postData['userImageUrl'] ?? '',
    };

    // --- LOGIC FOR MULTIPLE IMAGES ---
    final String postType = postData['postType'] ?? 'image';

    // Get list of images. If 'postImages' doesn't exist (old posts), fallback to 'postMediaUrl' inside a list.
    List<String> mediaUrls = [];
    if (postData['postImages'] != null &&
        (postData['postImages'] as List).isNotEmpty) {
      mediaUrls = List<String>.from(postData['postImages']);
    } else if (postData['postMediaUrl'] != null &&
        postData['postMediaUrl'] != '') {
      mediaUrls.add(postData['postMediaUrl']);
    }

    final String? originalThumbnailUrl = postData['postThumbnailUrl'];
    final String caption = postData['caption'] ?? '';
    final bool isAuthor = postData['userId'] == currentUserId;
    final timestamp = (postData['timestamp'] as Timestamp?)?.toDate();
    final String heroTag = 'post-${widget.postSnapshot.id}';

    return Container(
      margin: const EdgeInsets.only(bottom: 1.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 10.0,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onProfileTapped,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage:
                        authorData['profilePhotoUrl'].isNotEmpty
                            ? CachedNetworkImageProvider(
                              authorData['profilePhotoUrl'],
                            )
                            : null,
                    child:
                        authorData['profilePhotoUrl'].isEmpty
                            ? const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 20,
                            )
                            : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorData['displayName'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: brandBlack,
                        ),
                      ),
                      if (authorData['username'].isNotEmpty)
                        Text(
                          '@${authorData['username']}',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                // --- 3-DOT MENU FOR EDIT/DELETE ---
                if (isAuthor)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') widget.onEditPressed();
                      if (value == 'delete') widget.onDeletePressed();
                    },
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    itemBuilder:
                        (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.black54),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
              ],
            ),
          ),

          // --- MEDIA CAROUSEL OR VIDEO ---
          if (postType == 'video')
            // 1. VIDEO PLAYER
            GestureDetector(
              onTap: () {
                if (mediaUrls.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) =>
                              FullScreenVideoPlayer(videoUrl: mediaUrls.first),
                    ),
                  );
                }
              },
              child: Hero(
                tag: heroTag,
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: getOptimizedCloudinaryUrl(
                          originalThumbnailUrl ?? '',
                        ),
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) =>
                                Container(color: Colors.grey[200]),
                        errorWidget:
                            (context, url, error) =>
                                Container(color: Colors.grey[100]),
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (mediaUrls.isNotEmpty)
            // 2. IMAGE CAROUSEL
            Column(
              children: [
                SizedBox(
                  height:
                      MediaQuery.of(context).size.width, // Square aspect ratio
                  child: PageView.builder(
                    itemCount: mediaUrls.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => FullScreenImageViewer(
                                    imageUrl: mediaUrls[index],
                                    heroTag:
                                        '$heroTag-$index', // Unique tag per image
                                  ),
                            ),
                          );
                        },
                        child: Hero(
                          tag: '$heroTag-$index',
                          child: CachedNetworkImage(
                            imageUrl: getOptimizedCloudinaryUrl(
                              mediaUrls[index],
                            ),
                            fit: BoxFit.cover,
                            memCacheWidth: 1080,
                            fadeInDuration: const Duration(milliseconds: 300),
                            placeholder:
                                (context, url) =>
                                    Container(color: Colors.grey[200]),
                            errorWidget:
                                (context, url, error) =>
                                    const Icon(Icons.error),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // 3. DOTS INDICATOR / BANNER
                if (mediaUrls.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(mediaUrls.length, (index) {
                        return Container(
                          width: 6.0,
                          height: 6.0,
                          margin: const EdgeInsets.symmetric(horizontal: 3.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _currentImageIndex == index
                                    ? Colors.blue
                                    : Colors.grey.withOpacity(0.4),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),

          // --- ACTIONS BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 10.0,
            ),
            child: StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postSnapshot.id)
                      .snapshots(),
              builder: (context, snapshot) {
                final likesData =
                    snapshot.hasData
                        ? snapshot.data!.data() as Map<String, dynamic>
                        : postData;
                final rtLikes = likesData['likes'] ?? [];
                final bool isLiked = rtLikes.contains(currentUserId);

                return Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onLikePressed,
                      child: Icon(
                        isLiked
                            ? Icons.favorite
                            : Icons.favorite_border_rounded,
                        color: isLiked ? Colors.redAccent : Colors.black,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: widget.onCommentPressed,
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _onSharePressed(context),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // --- CAPTION & LIKES ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('posts')
                          .doc(widget.postSnapshot.id)
                          .snapshots(),
                  builder: (context, snapshot) {
                    final likesData =
                        snapshot.hasData
                            ? snapshot.data!.data() as Map<String, dynamic>
                            : postData;
                    final rtLikes = likesData['likes'] ?? [];
                    if (rtLikes.isEmpty) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text(
                        "${rtLikes.length} likes",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    );
                  },
                ),

                if (caption.isNotEmpty)
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        color: brandBlack,
                        fontSize: 13,
                        height: 1.3,
                      ),
                      children: [
                        TextSpan(
                          text: "${authorData['displayName']} ",
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: caption),
                      ],
                    ),
                  ),

                const SizedBox(height: 4),
                Text(
                  timestamp != null ? timeago_format(timestamp) : '',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String timeago_format(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) return DateFormat('MMM d').format(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
