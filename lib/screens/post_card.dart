// ===============================
// FILE NAME: post_card.dart
// FILE PATH: lib/screens/post_card.dart
// ===============================

// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:visibility_detector/visibility_detector.dart'; // REQUIRED PACKAGE

import 'full_screen_video_player.dart';
import 'share_post_sheet.dart';
import 'likes_list_screen.dart';

// --- ROBUST GLOBAL AUDIO HANDLER ---
class GlobalAudioHandler {
  static final AudioPlayer _player = AudioPlayer();
  static String? _currentPostId;
  static Function(bool)? _currentUiUpdater;

  static void init() {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  static Future<void> playOrPause(
    String postId,
    String url,
    Function(bool) updateUi,
  ) async {
    try {
      if (_currentPostId == postId) {
        // Toggle same song
        if (_player.state == PlayerState.playing) {
          await _player.pause();
          updateUi(false);
        } else {
          await _player.resume();
          updateUi(true);
        }
      } else {
        // Stop old song
        await _player.stop();
        if (_currentUiUpdater != null) _currentUiUpdater!(false);

        // Play new song
        _currentPostId = postId;
        _currentUiUpdater = updateUi;
        await _player.play(UrlSource(url));
        updateUi(true);

        // Auto-reset when finished
        _player.onPlayerComplete.listen((_) {
          if (_currentPostId == postId) {
            updateUi(false);
            _currentPostId = null;
          }
        });
      }
    } catch (e) {
      debugPrint("Audio Error: $e");
      updateUi(false);
    }
  }

  // Called by VisibilityDetector
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
  int _currentImageIndex = 0;
  bool _isPlayingMusic = false;

  // Animation State
  bool _isPowerAnimating = false;
  AnimationController? _likeController;
  late Animation<double> _likeScaleAnimation;
  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();

    // Initialize Animation Controller
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _likeController!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    // Backup stop in case VisibilityDetector misses it (rare)
    if (_isPlayingMusic) {
      GlobalAudioHandler.stopIfPlaying(widget.postSnapshot.id);
    }

    _likeController?.dispose();
    _animationTimer?.cancel();
    super.dispose();
  }

  // --- VISIBILITY LOGIC (STOPS MUSIC ON SCROLL) ---
  void _onVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction == 0) {
      // Post is completely off screen -> Stop Music
      if (_isPlayingMusic) {
        GlobalAudioHandler.stopIfPlaying(widget.postSnapshot.id);
        if (mounted) setState(() => _isPlayingMusic = false);
      }
    }
  }

  // --- AUDIO LOGIC ---
  void _toggleMusic(String? url) {
    if (url == null || url.isEmpty) return;

    GlobalAudioHandler.playOrPause(widget.postSnapshot.id, url, (isPlaying) {
      if (mounted) {
        setState(() {
          _isPlayingMusic = isPlaying;
        });
      }
    });
  }

  // --- LIKE LOGIC ---
  void _handleDoubleTapLike() {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // 1. Database: Add Like (never remove)
    FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postSnapshot.id)
        .update({
          'likes': FieldValue.arrayUnion([currentUserId]),
        });

    // 2. Button Bounce Animation
    if (_likeController != null) {
      _likeController!.forward().then((_) => _likeController!.reverse());
    }

    // 3. Overlay Animation (handle rapid taps)
    _animationTimer?.cancel();
    setState(() {
      _isPowerAnimating = true;
    });

    _animationTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isPowerAnimating = false;
        });
      }
    });
  }

  void _openLikesScreen(List<dynamic> likes) {
    if (likes.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LikesListScreen(likeUserIds: likes),
      ),
    );
  }

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

  // --- UI WIDGETS ---
  Widget _buildAudioControl(String? previewUrl) {
    if (previewUrl == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 12,
      right: 12,
      child: GestureDetector(
        onTap: () => _toggleMusic(previewUrl),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(
            _isPlayingMusic
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildPowerOverlay() {
    if (!_isPowerAnimating) return const SizedBox.shrink();

    return Positioned.fill(
      child: Center(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(DateTime.now()), // Restart animation on every tap
          tween: Tween(begin: 0.0, end: 1.2),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: const Icon(
                  Icons.bolt_rounded, // Power Symbol
                  color: Colors.white,
                  size: 110,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postData = widget.postSnapshot.data() as Map<String, dynamic>?;
    if (postData == null) return const SizedBox.shrink();

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    const Color brandBlack = Colors.black;

    final authorData = {
      'displayName': postData['userName'] ?? 'Unknown',
      'username': postData['username'] ?? '',
      'profilePhotoUrl': postData['userImageUrl'] ?? '',
    };

    final Map<String, dynamic>? musicData = postData['music'];
    final String? musicTitle = musicData?['trackName'];
    final String? musicArtist = musicData?['artistName'];
    final String? musicPreviewUrl = musicData?['previewUrl'];

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

    return VisibilityDetector(
      key: Key('post-vis-${widget.postSnapshot.id}'),
      onVisibilityChanged:
          _onVisibilityChanged, // Stops music when scrolled away
      child: Container(
        margin: const EdgeInsets.only(bottom: 24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(0),
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
                      radius: 20,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorData['displayName'],
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: brandBlack,
                          ),
                        ),
                        if (musicTitle != null)
                          GestureDetector(
                            onTap: () => _toggleMusic(musicPreviewUrl),
                            child: Row(
                              children: [
                                Icon(
                                  _isPlayingMusic
                                      ? Icons.graphic_eq
                                      : Icons.music_note,
                                  size: 12,
                                  color:
                                      _isPlayingMusic
                                          ? Colors.deepPurple
                                          : Colors.grey[700],
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    "$musicTitle • $musicArtist",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color:
                                          _isPlayingMusic
                                              ? Colors.deepPurple
                                              : Colors.grey[700],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (authorData['username'].isNotEmpty)
                          Text(
                            '@${authorData['username']}',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isAuthor)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') widget.onEditPressed();
                        if (value == 'delete') widget.onDeletePressed();
                      },
                      icon: const Icon(Icons.more_horiz, color: Colors.black54),
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

            // --- MEDIA CONTENT ---
            if (postType == 'video')
              GestureDetector(
                onTap: () {
                  if (mediaUrls.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => FullScreenVideoPlayer(
                              videoUrl: mediaUrls.first,
                            ),
                      ),
                    );
                  }
                },
                onDoubleTap: _handleDoubleTapLike,
                child: Hero(
                  tag: 'post-${widget.postSnapshot.id}',
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
                        _buildAudioControl(musicPreviewUrl),
                        _buildPowerOverlay(),
                      ],
                    ),
                  ),
                ),
              )
            else if (mediaUrls.isNotEmpty)
              Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.width,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PageView.builder(
                          itemCount: mediaUrls.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onDoubleTap: _handleDoubleTapLike,
                              child: InteractiveViewer(
                                clipBehavior: Clip.none,
                                minScale: 1.0,
                                maxScale: 4.0,
                                child: CachedNetworkImage(
                                  imageUrl: getOptimizedCloudinaryUrl(
                                    mediaUrls[index],
                                  ),
                                  fit: BoxFit.cover,
                                  memCacheWidth: 1080,
                                  fadeInDuration: const Duration(
                                    milliseconds: 300,
                                  ),
                                  placeholder:
                                      (context, url) =>
                                          Container(color: Colors.grey[100]),
                                  errorWidget:
                                      (context, url, error) =>
                                          const Icon(Icons.error),
                                ),
                              ),
                            );
                          },
                        ),
                        _buildAudioControl(musicPreviewUrl),
                        _buildPowerOverlay(),
                      ],
                    ),
                  ),
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
                vertical: 12.0,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // LIKE (Power Bolt)
                          GestureDetector(
                            onTap: widget.onLikePressed,
                            child: ScaleTransition(
                              scale: _likeScaleAnimation,
                              child: Icon(
                                isLiked
                                    ? Icons.bolt_rounded
                                    : Icons.bolt_outlined,
                                color:
                                    isLiked
                                        ? Colors.amber[700]
                                        : Colors.black87,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),

                          // COMMENT
                          GestureDetector(
                            onTap: widget.onCommentPressed,
                            child: const Icon(
                              Icons.mode_comment_outlined,
                              color: Colors.black87,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 18),

                          // SHARE
                          GestureDetector(
                            onTap: () => _onSharePressed(context),
                            child: const Icon(
                              Icons.near_me_outlined,
                              color: Colors.black87,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            // --- CAPTION & LIKES COUNT ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
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
                      final bool isLiked = rtLikes.contains(currentUserId);
                      final int count = rtLikes.length;

                      if (count == 0) return const SizedBox.shrink();

                      Widget likeTextWidget;
                      if (isLiked) {
                        if (count == 1) {
                          likeTextWidget = RichText(
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                              children: [
                                const TextSpan(text: "Liked by "),
                                TextSpan(
                                  text: "you",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          likeTextWidget = RichText(
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                              children: [
                                const TextSpan(text: "Liked by "),
                                TextSpan(
                                  text: "you",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const TextSpan(text: " and "),
                                TextSpan(
                                  text: "${count - 1} others",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      } else {
                        likeTextWidget = Text(
                          "$count ${count == 1 ? 'like' : 'likes'}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: GestureDetector(
                          onTap: () => _openLikesScreen(rtLikes),
                          child: likeTextWidget,
                        ),
                      );
                    },
                  ),
                  if (caption.isNotEmpty)
                    RichText(
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          color: brandBlack,
                          fontSize: 13,
                          height: 1.4,
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
                  const SizedBox(height: 6),
                  Text(
                    timestamp != null ? timeago_format(timestamp) : '',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
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
