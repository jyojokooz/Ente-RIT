// ===============================
// FILE NAME: post_card.dart
// FILE PATH: lib/screens/post_card.dart
// ===============================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'full_screen_video_player.dart';
import 'share_post_sheet.dart';
import 'likes_list_screen.dart';

// Reuse GlobalAudioHandler from your existing code...
class GlobalAudioHandler {
  static final AudioPlayer _player = AudioPlayer();
  static String? _currentPostId;
  static Function(bool)? _currentUiUpdater;

  static void init() => _player.setReleaseMode(ReleaseMode.stop);

  static Future<void> playOrPause(
    String postId,
    String url,
    Function(bool) updateUi,
  ) async {
    try {
      if (_currentPostId == postId) {
        if (_player.state == PlayerState.playing) {
          await _player.pause();
          updateUi(false);
        } else {
          await _player.resume();
          updateUi(true);
        }
      } else {
        await _player.stop();
        if (_currentUiUpdater != null) _currentUiUpdater!(false);

        _currentPostId = postId;
        _currentUiUpdater = updateUi;
        await _player.play(UrlSource(url));
        updateUi(true);

        _player.onPlayerComplete.listen((_) {
          if (_currentPostId == postId) {
            updateUi(false);
            _currentPostId = null;
          }
        });
      }
    } catch (e) {
      updateUi(false);
    }
  }

  static void stopIfPlaying(String postId) async {
    if (_currentPostId == postId) {
      await _player.stop();
      if (_currentUiUpdater != null) _currentUiUpdater!(false);
      _currentPostId = null;
      _currentUiUpdater = null;
    }
  }
}

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

class _PostCardState extends State<PostCard> with TickerProviderStateMixin {
  bool _isPlayingMusic = false;
  AnimationController? _likeController;
  late Animation<double> _likeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _likeController!, curve: Curves.elasticOut),
    );
  }

  @override
  void deactivate() {
    if (_isPlayingMusic) {
      GlobalAudioHandler.stopIfPlaying(widget.postSnapshot.id);
      _isPlayingMusic = false;
    }
    super.deactivate();
  }

  @override
  void dispose() {
    if (_isPlayingMusic)
      GlobalAudioHandler.stopIfPlaying(widget.postSnapshot.id);
    _likeController?.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction == 0 && _isPlayingMusic) {
      GlobalAudioHandler.stopIfPlaying(widget.postSnapshot.id);
      if (mounted) setState(() => _isPlayingMusic = false);
    }
  }

  void _triggerLikeButtonPress() {
    widget.onLikePressed();
    if (_likeController != null)
      _likeController!.forward().then((_) => _likeController!.reverse());
  }

  String getOptimizedCloudinaryUrl(String originalUrl) {
    if (!originalUrl.contains('res.cloudinary.com')) return originalUrl;
    const transformations = 'w_1080,q_auto:good,f_auto';
    final parts = originalUrl.split('/upload/');
    if (parts.length == 2)
      return '${parts[0]}/upload/$transformations/${parts[1]}';
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Matching design colors
    final cardBgColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    final postData = widget.postSnapshot.data() as Map<String, dynamic>?;
    if (postData == null) return const SizedBox.shrink();

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final authorData = {
      'displayName': postData['userName'] ?? 'Unknown',
      'profilePhotoUrl': postData['userImageUrl'] ?? '',
    };

    final String postType = postData['postType'] ?? 'image';
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
    final rtLikes = postData['likes'] ?? [];
    final bool isLiked = rtLikes.contains(currentUserId);
    final int commentsCount = postData['comments'] ?? 0;

    return VisibilityDetector(
      key: Key('post-vis-${widget.postSnapshot.id}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              children: [
                GestureDetector(
                  onTap: widget.onProfileTapped,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    backgroundImage:
                        authorData['profilePhotoUrl'].isNotEmpty
                            ? CachedNetworkImageProvider(
                              authorData['profilePhotoUrl'],
                            )
                            : null,
                    child:
                        authorData['profilePhotoUrl'].isEmpty
                            ? Icon(Icons.person, color: subtitleColor)
                            : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorData['displayName'],
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        timestamp != null ? _formatTimeAgo(timestamp) : '',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAuthor)
                  PopupMenuButton<String>(
                    color: theme.colorScheme.surface,
                    onSelected: (val) {
                      if (val == 'edit') widget.onEditPressed();
                      if (val == 'delete') widget.onDeletePressed();
                    },
                    icon: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.more_horiz, size: 20),
                    ),
                    itemBuilder:
                        (ctx) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(
                              'Edit',
                              style: TextStyle(color: textColor),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // --- CONTENT AREA (Vibrant inner box) ---
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Background: Image OR Gradient
                  if (mediaUrls.isNotEmpty)
                    AspectRatio(
                      aspectRatio: postType == 'video' ? 1.0 : 4 / 3,
                      child: CachedNetworkImage(
                        imageUrl: getOptimizedCloudinaryUrl(
                          postType == 'video'
                              ? (originalThumbnailUrl ?? '')
                              : mediaUrls.first,
                        ),
                        fit: BoxFit.cover,
                        placeholder:
                            (c, u) => Container(
                              color:
                                  isDark
                                      ? Colors.white10
                                      : Colors.grey.shade200,
                            ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 180),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFF3E8E),
                            Color(0xFFFF9A44),
                          ], // Pink to Orange gradient
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

                  // Overlay Gradient for text readability
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Caption Text over Image/Gradient
                  Positioned(
                    bottom: 70,
                    left: 16,
                    right: 16,
                    child: Text(
                      caption,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Interaction Pills inside the box (Bottom)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Comment Pill
                        GestureDetector(
                          onTap: widget.onCommentPressed,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(
                                0.2,
                              ), // Frosted glass effect
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.chat_bubble_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "$commentsCount Comments",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Like & Bookmark Row
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _triggerLikeButtonPress,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    ScaleTransition(
                                      scale: _likeScaleAnimation,
                                      child: Icon(
                                        isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color:
                                            isLiked
                                                ? Colors.redAccent
                                                : Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${rtLikes.length}",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: theme.colorScheme.surface,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder:
                                      (context) => SharePostSheet(
                                        postId: widget.postSnapshot.id,
                                      ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.near_me_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Play button for video
                  if (postType == 'video')
                    Positioned.fill(
                      child: Center(
                        child: GestureDetector(
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => FullScreenVideoPlayer(
                                        videoUrl: mediaUrls.first,
                                      ),
                                ),
                              ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) return DateFormat('MMM d').format(date);
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} mins ago';
    return 'Just now';
  }
}
