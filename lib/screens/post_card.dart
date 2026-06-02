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

import '../helpers/app_cache_manager.dart';

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

  // --- UPDATED: Firebase Storage doesn't support URL transformations natively. ---
  // Returns original URL without Cloudinary alterations.
  String getOptimizedUrl(String originalUrl) {
    return originalUrl;
  }

  String _getAcronym(String name) {
    if (name.isEmpty) return "";
    String lowerName = name.toLowerCase();

    if (lowerName.contains("mca") || lowerName.contains("application"))
      return "MCA";
    if (lowerName.contains("computer")) return "CSE";
    if (lowerName.contains("mechanical")) return "ME";
    if (lowerName.contains("electrical") && lowerName.contains("electronics"))
      return "EEE";
    if (lowerName.contains("electronics") &&
        lowerName.contains("communication"))
      return "ECE";
    if (lowerName.contains("civil")) return "CE";
    if (lowerName.contains("architecture")) return "B.Arch";

    List<String> words = name.split(" ");
    if (words.length > 1) {
      return words.take(2).map((e) => e[0].toUpperCase()).join();
    }
    return name.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final postData = widget.postSnapshot.data() as Map<String, dynamic>?;
    if (postData == null) return const SizedBox.shrink();

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark ? const Color(0xFF121215) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER (Avatar, Name, Dept, Time) ---
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(postAuthorId)
                      .snapshots(),
              builder: (context, authorSnap) {
                String currentDisplayName = postData['userName'] ?? 'Unknown';
                String currentProfilePic = postData['userImageUrl'] ?? '';
                String department = '';

                if (authorSnap.hasData && authorSnap.data!.exists) {
                  final authorDocData =
                      authorSnap.data!.data() as Map<String, dynamic>;
                  currentDisplayName =
                      authorDocData['displayName'] ?? currentDisplayName;
                  currentProfilePic =
                      authorDocData['profilePhotoUrl'] ?? currentProfilePic;
                  department = authorDocData['department'] ?? '';
                }

                String deptAcronym = _getAcronym(department);
                String formattedTime =
                    timestamp != null
                        ? DateFormat("MMM d 'at' h:mm a").format(timestamp)
                        : '';

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: widget.onProfileTapped,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF9983F3), Color(0xFFFF4B72)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            shape: BoxShape.circle,
                          ),
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
                                      cacheManager: AppCacheManager.instance,
                                    )
                                    : null,
                            child:
                                currentProfilePic.isEmpty
                                    ? Icon(Icons.person, color: subtitleColor)
                                    : null,
                          ),
                        ),
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
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                formattedTime,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: subtitleColor,
                                ),
                              ),
                              if (deptAcronym.isNotEmpty) ...[
                                Text(
                                  ' • ',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: subtitleColor,
                                  ),
                                ),
                                Text(
                                  deptAcronym,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(
                                      0xFF9983F3,
                                    ), // Accent Purple
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
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
                        icon: Icon(
                          Icons.more_horiz,
                          color: subtitleColor,
                          size: 24,
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
            const SizedBox(height: 12),

            // --- CAPTION / TEXT CONTENT ---
            if (caption.isNotEmpty) ...[
              Text(
                caption,
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // --- MEDIA DISPLAY (FORCED LANDSCAPE 16:9) ---
            if (mediaUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
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
                        // FORCED WIDE LANDSCAPE RATIO
                        aspectRatio: 16 / 9,
                        child: Hero(
                          tag: 'post_${widget.postSnapshot.id}',
                          child: CachedNetworkImage(
                            imageUrl: getOptimizedUrl(
                              postType == 'video'
                                  ? (originalThumbnailUrl ?? '')
                                  : mediaUrls.first,
                            ),
                            cacheManager: AppCacheManager.instance,
                            fit:
                                BoxFit
                                    .cover, // Ensures image fills the 16:9 box nicely
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
                    ),

                    // Multi-image indicator (Top Right)
                    if (mediaUrls.length > 1)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "1/${mediaUrls.length}",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                    // Video Play Button Overlay
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

                    // Music Pill Overlay (Bottom Left)
                    if (postType == 'image' &&
                        musicData != null &&
                        musicData['previewUrl'] != null)
                      Positioned(
                        bottom: 12,
                        left: 12,
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
                              color: Colors.black.withOpacity(0.7),
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
                  ],
                ),
              ),

            if (mediaUrls.isNotEmpty) const SizedBox(height: 16),

            // --- BOTTOM ACTIONS (Like, Comment, Share) ---
            Row(
              children: [
                // Like Button
                GestureDetector(
                  onTap: _triggerLikeButtonPress,
                  child: Row(
                    children: [
                      ScaleTransition(
                        scale: _likeScaleAnimation,
                        child: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color:
                              _isLiked
                                  ? const Color(0xFFFF4B72)
                                  : subtitleColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "$_likesCount",
                        style: GoogleFonts.poppins(
                          color: subtitleColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Comment Button
                GestureDetector(
                  onTap: widget.onCommentPressed,
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: subtitleColor,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "$commentsCount",
                        style: GoogleFonts.poppins(
                          color: subtitleColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Share Button
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
                          (context) =>
                              SharePostSheet(postId: widget.postSnapshot.id),
                    );
                  },
                  child: Icon(
                    Icons.near_me_outlined,
                    color: subtitleColor,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
