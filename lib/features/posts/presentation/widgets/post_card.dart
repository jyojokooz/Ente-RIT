// ===============================
// FILE NAME: post_card.dart
// FILE PATH: lib/features/posts/presentation/widgets/post_card.dart
// ===============================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:video_player/video_player.dart';

import 'package:my_project/core/widgets/media_viewers/media_viewers_connector.dart';
import 'package:my_project/features/posts/presentation/widgets/share_post_sheet.dart';
import 'package:my_project/core/utils/app_cache_manager.dart';

// --- GLOBAL AUDIO HANDLER ---
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

  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  final TransformationController _transformController =
      TransformationController();
  AnimationController? _zoomAnimationController;
  Animation<Matrix4>? _zoomAnimation;

  bool _isCaptionExpanded = false;

  // Optimistic UI State
  late bool _isLiked;
  late int _likesCount;
  bool _showHeartOverlay = false;

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

    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
      _transformController.value = _zoomAnimation!.value;
    });

    _initializeLikeState();

    final postData = widget.postSnapshot.data() as Map<String, dynamic>?;
    if (postData != null && postData['postType'] == 'video') {
      String url = postData['postMediaUrl'] ?? postData['postImageUrl'] ?? '';
      if (url.isNotEmpty) {
        _videoController =
            VideoPlayerController.networkUrl(
                Uri.parse(url),
                httpHeaders: {'User-Agent': 'EnteRITApp'},
              )
              ..setVolume(0) // Muted inline autoplay
              ..setLooping(true)
              ..initialize()
                  .then((_) {
                    if (mounted) setState(() => _isVideoInitialized = true);
                  })
                  .catchError((e) {
                    debugPrint('PostCard Video Init Error: $e');
                  });
      }
    }
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
    _videoController?.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    if (_isPlayingMusic) {
      GlobalAudioHandler.stopIfPlaying(widget.postSnapshot.id);
    }
    _videoController?.dispose();
    _transformController.dispose();
    _zoomAnimationController?.dispose();
    _likeController?.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _zoomAnimation = Matrix4Tween(
      begin: _transformController.value,
      end: Matrix4.identity(),
    ).animate(
      CurvedAnimation(
        parent: _zoomAnimationController!,
        curve: Curves.easeOutCubic,
      ),
    );
    _zoomAnimationController!.forward(from: 0);
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction > 0.6) {
      if (_videoController != null && !_videoController!.value.isPlaying) {
        _videoController!.play();
      }
    } else {
      if (_videoController != null && _videoController!.value.isPlaying) {
        _videoController!.pause();
      }
      if (info.visibleFraction < 0.2 && _isPlayingMusic) {
        GlobalAudioHandler.stopIfPlaying(widget.postSnapshot.id);
        if (mounted) setState(() => _isPlayingMusic = false);
      }
    }
  }

  void _triggerDoubleTapLike() {
    setState(() {
      _showHeartOverlay = true;
    });

    Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showHeartOverlay = false);
    });

    if (!_isLiked) {
      _triggerLikeButtonPress();
    }
  }

  void _triggerLikeButtonPress() {
    final bool newLikeState = !_isLiked;

    setState(() {
      _isLiked = newLikeState;
      _likesCount += newLikeState ? 1 : -1;
    });

    if (_likeController != null) {
      _likeController!.forward().then((_) => _likeController!.reverse());
    }

    widget.onLikePressed(newLikeState);
  }

  String _formatTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Now';
  }

  @override
  Widget build(BuildContext context) {
    final postData = widget.postSnapshot.data() as Map<String, dynamic>?;
    if (postData == null) return const SizedBox.shrink();

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Set exactly to your home screen's background color so it seamlessly blends edge-to-edge
    final cardBgColor =
        isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE);
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
    final String location = postData['location'] ?? '';

    return VisibilityDetector(
      key: Key('post-vis-${widget.postSnapshot.id}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        color: cardBgColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(postAuthorId)
                      .snapshots(),
              builder: (context, authorSnap) {
                String currentDisplayName = postData['userName'] ?? 'Unknown';
                String currentProfilePic = postData['userImageUrl'] ?? '';

                if (authorSnap.hasData && authorSnap.data!.exists) {
                  final authorDocData =
                      authorSnap.data!.data() as Map<String, dynamic>;
                  currentDisplayName =
                      authorDocData['displayName'] ?? currentDisplayName;
                  currentProfilePic =
                      authorDocData['profilePhotoUrl'] ?? currentProfilePic;
                }

                String formattedTime =
                    timestamp != null ? _formatTime(timestamp) : '';

                String subText = '';
                if (musicData != null && musicData['trackName'] != null) {
                  subText =
                      "${musicData['artistName']} • ${musicData['trackName']}";
                } else if (location.isNotEmpty) {
                  subText = location;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Profile Click Area
                      GestureDetector(
                        onTap: widget.onProfileTapped,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF9983F3),
                                    Color(0xFFFF4B72),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200,
                                backgroundImage:
                                    currentProfilePic.isNotEmpty
                                        ? CachedNetworkImageProvider(
                                          currentProfilePic,
                                          cacheManager:
                                              AppCacheManager.instance,
                                        )
                                        : null,
                                child:
                                    currentProfilePic.isEmpty
                                        ? Icon(
                                          Icons.person,
                                          color: subtitleColor,
                                          size: 20,
                                        )
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      currentDisplayName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• $formattedTime',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: subtitleColor,
                                      ),
                                    ),
                                  ],
                                ),
                                if (subText.isNotEmpty)
                                  Row(
                                    children: [
                                      if (musicData != null)
                                        Icon(
                                          _isPlayingMusic
                                              ? Icons.graphic_eq
                                              : Icons.music_note_rounded,
                                          size: 12,
                                          color: textColor,
                                        ),
                                      if (musicData != null)
                                        const SizedBox(width: 4),
                                      Text(
                                        subText,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        color: theme.colorScheme.surface,
                        onSelected: (val) async {
                          if (val == 'edit') widget.onEditPressed();
                          if (val == 'delete') widget.onDeletePressed();
                          if (val == 'report') {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('reported_content')
                                  .add({
                                    'postId': widget.postSnapshot.id,
                                    'reportedBy': currentUserId,
                                    'authorId': postAuthorId,
                                    'timestamp': FieldValue.serverTimestamp(),
                                    'status': 'pending_review',
                                  });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Post reported."),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Failed to report."),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        icon: Icon(
                          Icons.more_horiz,
                          color: textColor,
                          size: 24,
                        ),
                        itemBuilder:
                            (ctx) => [
                              if (isAuthor) ...[
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
                              ] else ...[
                                const PopupMenuItem(
                                  value: 'report',
                                  child: Text(
                                    'Report',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ],
                      ),
                    ],
                  ),
                );
              },
            ),

            // --- MEDIA (EDGE TO EDGE) ---
            if (mediaUrls.isNotEmpty)
              GestureDetector(
                onDoubleTap: _triggerDoubleTapLike,
                onTap: () {
                  if (postType == 'video' && mediaUrls.first.isNotEmpty) {
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
                  }
                },
                child: AspectRatio(
                  aspectRatio: 4 / 5, // Standard modern portrait feed ratio
                  child: Stack(
                    children: [
                      postType == 'video'
                          ? (_isVideoInitialized && _videoController != null
                              ? SizedBox.expand(
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _videoController!.value.size.width,
                                    height: _videoController!.value.size.height,
                                    child: VideoPlayer(_videoController!),
                                  ),
                                ),
                              )
                              : _buildNetworkImage(
                                originalThumbnailUrl ?? '',
                                isDark,
                              ))
                          : InteractiveViewer(
                            transformationController: _transformController,
                            panEnabled: true,
                            scaleEnabled: true,
                            minScale: 1.0,
                            maxScale: 4.0,
                            clipBehavior: Clip.none,
                            onInteractionEnd: (_) => _resetZoom(),
                            child: _buildNetworkImage(mediaUrls.first, isDark),
                          ),

                      // Multi Image Badge
                      if (mediaUrls.length > 1)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "1/${mediaUrls.length}",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      // Fast Pop-up Heart Animation Overlay
                      if (_showHeartOverlay)
                        Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.5, end: 1.2),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.elasticOut,
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: Icon(
                                  Icons.favorite,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 100,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // --- BOTTOM ACTIONS ---
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12, top: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _triggerLikeButtonPress,
                    icon: ScaleTransition(
                      scale: _likeScaleAnimation,
                      child: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? const Color(0xFFFF4B72) : textColor,
                        size: 26,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onCommentPressed,
                    icon: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: textColor,
                      size: 24,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
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
                            (context) =>
                                SharePostSheet(postId: widget.postSnapshot.id),
                      );
                    },
                    icon: Icon(Icons.send_outlined, color: textColor, size: 24),
                  ),
                  const Spacer(),
                  // Visual Bookmark Button (non-functional right align like IG)
                  Icon(Icons.bookmark_border, color: textColor, size: 26),
                ],
              ),
            ),

            // --- LIKES COUNT ---
            if (_likesCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "$_likesCount likes",
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),

            // --- CAPTION ---
            if (caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(color: textColor, fontSize: 13),
                    children: [
                      TextSpan(
                        text: "${postData['userName'] ?? 'User'} ",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            _isCaptionExpanded || caption.length <= 100
                                ? caption
                                : "${caption.substring(0, 100)}...",
                      ),
                      if (!_isCaptionExpanded && caption.length > 100)
                        WidgetSpan(
                          child: GestureDetector(
                            onTap:
                                () => setState(() => _isCaptionExpanded = true),
                            child: Text(
                              " more",
                              style: TextStyle(color: subtitleColor),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // --- COMMENTS TRIGGER ---
            if (commentsCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: GestureDetector(
                  onTap: widget.onCommentPressed,
                  child: Text(
                    "View all $commentsCount comments",
                    style: GoogleFonts.poppins(
                      color: subtitleColor,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkImage(String url, bool isDark) {
    if (url.isEmpty) {
      return Container(color: isDark ? Colors.white10 : Colors.grey.shade200);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      cacheManager: AppCacheManager.instance,
      placeholder:
          (c, u) =>
              Container(color: isDark ? Colors.white10 : Colors.grey.shade200),
      errorWidget:
          (c, u, e) => Container(
            color: isDark ? Colors.black : Colors.white,
            child: const Icon(Icons.error, color: Colors.grey),
          ),
    );
  }
}
