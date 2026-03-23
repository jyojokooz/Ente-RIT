// ===============================
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
import 'full_screen_image_viewer.dart';
import 'share_post_sheet.dart';

// --- NEW IMPORT FOR AGGRESSIVE CACHING ---
import '../helpers/app_cache_manager.dart';

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
  final Function(bool isLikedNow) onLikePressed;
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

  // Optimistic UI State
  late bool _isLiked;
  late int _likesCount;

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

    _initializeLikeState();
  }

  void _initializeLikeState() {
    final postData = widget.postSnapshot.data() as Map<String, dynamic>;
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final List<dynamic> rtLikes = postData['likes'] ?? [];

    _isLiked = rtLikes.contains(currentUserId);
    _likesCount = rtLikes.length;
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initializeLikeState();
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
    if (_isPlayingMusic) {
      GlobalAudioHandler.stopIfPlaying(widget.postSnapshot.id);
    }
    _likeController?.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction < 0.5 && _isPlayingMusic) {
      GlobalAudioHandler.stopIfPlaying(widget.postSnapshot.id);
      if (mounted) setState(() => _isPlayingMusic = false);
    }
  }

  void _triggerLikeButtonPress() {
    final bool newLikeState = !_isLiked; // Determine the intended new state

    setState(() {
      _isLiked = newLikeState;
      _likesCount += newLikeState ? 1 : -1;
    });

    if (_likeController != null) {
      _likeController!.forward().then((_) => _likeController!.reverse());
    }

    // Pass the new state back up to the parent screen
    widget.onLikePressed(newLikeState);
  }

  String getOptimizedCloudinaryUrl(String originalUrl) {
    if (!originalUrl.contains('res.cloudinary.com')) return originalUrl;
    const transformations = 'w_1080,q_auto:good,f_auto';
    final parts = originalUrl.split('/upload/');
    if (parts.length == 2) {
      return '${parts[0]}/upload/$transformations/${parts[1]}';
    }
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    final postData = widget.postSnapshot.data() as Map<String, dynamic>?;
    if (postData == null) return const SizedBox.shrink();

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    final String postAuthorId = postData['userId'] ?? '';
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
    final bool isAuthor = postAuthorId == currentUserId;
    final timestamp = (postData['timestamp'] as Timestamp?)?.toDate();
    final int commentsCount = postData['comments'] ?? 0;
    final Map<String, dynamic>? musicData = postData['music'];

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
            // --- HEADER (Instantly listens to user's live profile changes) ---
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(postAuthorId)
                      .snapshots(),
              builder: (context, authorSnap) {
                // Fallback to static post data if loading
                String currentDisplayName = postData['userName'] ?? 'Unknown';
                String currentProfilePic = postData['userImageUrl'] ?? '';

                // If stream gets live data, overwrite the static data instantly
                if (authorSnap.hasData && authorSnap.data!.exists) {
                  final authorDocData =
                      authorSnap.data!.data() as Map<String, dynamic>;
                  currentDisplayName =
                      authorDocData['displayName'] ?? currentDisplayName;
                  currentProfilePic =
                      authorDocData['profilePhotoUrl'] ?? currentProfilePic;
                }

                return Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onProfileTapped,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                        backgroundImage:
                            currentProfilePic.isNotEmpty
                                ? CachedNetworkImageProvider(
                                  currentProfilePic,
                                  // --- CACHE MANAGER APPLIED HERE ---
                                  cacheManager: AppCacheManager.instance,
                                )
                                : null,
                        child:
                            currentProfilePic.isEmpty
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
                            currentDisplayName,
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
                            color:
                                isDark ? Colors.white10 : Colors.grey.shade100,
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
                );
              },
            ),
            const SizedBox(height: 16),

            // --- CONTENT AREA ---
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Background Image/Video
                  if (mediaUrls.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        if (postType == 'video') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => FullScreenVideoPlayer(
                                    videoUrl: mediaUrls.first,
                                    postId: widget.postSnapshot.id,
                                  ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => FullScreenImageViewer(
                                    imageUrl: mediaUrls.first,
                                    heroTag: 'post_${widget.postSnapshot.id}',
                                    postId: widget.postSnapshot.id,
                                  ),
                            ),
                          );
                        }
                      },
                      child: AspectRatio(
                        aspectRatio: postType == 'video' ? 1.0 : 4 / 3,
                        child: Hero(
                          tag: 'post_${widget.postSnapshot.id}',
                          child: CachedNetworkImage(
                            imageUrl: getOptimizedCloudinaryUrl(
                              postType == 'video'
                                  ? (originalThumbnailUrl ?? '')
                                  : mediaUrls.first,
                            ),
                            // --- CACHE MANAGER APPLIED HERE ---
                            cacheManager: AppCacheManager.instance,
                            fit: BoxFit.cover,
                            placeholder:
                                (c, u) => Container(
                                  color:
                                      isDark
                                          ? Colors.white10
                                          : Colors.grey.shade200,
                                ),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 180),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF3E8E), Color(0xFFFF9A44)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

                  // Overlay Gradient for text readability
                  Positioned.fill(
                    child: IgnorePointer(
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
                  ),

                  // --- MUSIC PILL OVERLAY ---
                  if (postType == 'image' &&
                      musicData != null &&
                      musicData['previewUrl'] != null)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: GestureDetector(
                        onTap: () {
                          GlobalAudioHandler.playOrPause(
                            widget.postSnapshot.id,
                            musicData['previewUrl'],
                            (isPlaying) {
                              if (mounted)
                                setState(() => _isPlayingMusic = isPlaying);
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          constraints: const BoxConstraints(maxWidth: 160),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isPlayingMusic
                                    ? Icons.graphic_eq
                                    : Icons.music_note_rounded,
                                color:
                                    _isPlayingMusic
                                        ? const Color(0xFF00C6FB)
                                        : Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  musicData['trackName'] ?? 'Music',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Caption Text
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

                  // Interaction Pills (Bottom)
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
                              color: Colors.white.withOpacity(0.2),
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

                        // Like & Share Row
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
                                        _isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color:
                                            _isLiked
                                                ? Colors.redAccent
                                                : Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "$_likesCount",
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
                        child: IgnorePointer(
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
