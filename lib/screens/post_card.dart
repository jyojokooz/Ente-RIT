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
import 'package:visibility_detector/visibility_detector.dart';

import 'full_screen_video_player.dart';
import 'share_post_sheet.dart';
import 'likes_list_screen.dart';
import 'comments_sheet.dart'; // <--- IMPORT THE NEW SHEET

// --- GLOBAL AUDIO HANDLER ---
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
      debugPrint("Audio Error: $e");
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
  final Function()
  onCommentPressed; // Kept for compatibility, but not used for sheet
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
  AnimationController? _likeController;
  late Animation<double> _likeScaleAnimation;

  AnimationController? _overlayController;
  late Animation<double> _overlayScale;
  late Animation<double> _overlayOpacity;

  @override
  void initState() {
    super.initState();

    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _likeScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _likeController!, curve: Curves.easeOut));

    _overlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _overlayScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _overlayController!,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _overlayOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _overlayController!,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
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
    if (_isPlayingMusic) {
      GlobalAudioHandler.stopIfPlaying(widget.postSnapshot.id);
    }
    _likeController?.dispose();
    _overlayController?.dispose();
    super.dispose();
  }

  // --- SHOW COMMENTS SHEET ---
  void _showCommentsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Needed for full height/keyboard interaction
      backgroundColor: Colors.transparent, // Allows rounded corners to show
      useRootNavigator: true, // Ensures it covers bottom nav bar if needed
      builder:
          (context) => Padding(
            // IMPORTANT: Padding for keyboard is handled inside the sheet via MediaQuery
            // But we add this wrapper to ensure safe area if needed
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: CommentsSheet(postId: widget.postSnapshot.id),
          ),
    );
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction == 0 && _isPlayingMusic) {
      GlobalAudioHandler.stopIfPlaying(widget.postSnapshot.id);
      if (mounted) setState(() => _isPlayingMusic = false);
    }
  }

  void _toggleMusic(String? url) {
    if (url == null || url.isEmpty) return;
    GlobalAudioHandler.playOrPause(widget.postSnapshot.id, url, (isPlaying) {
      if (mounted) setState(() => _isPlayingMusic = isPlaying);
    });
  }

  void _handleDoubleTapLike() {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postSnapshot.id)
        .update({
          'likes': FieldValue.arrayUnion([currentUserId]),
        });

    if (_likeController != null) {
      _likeController!.forward().then((_) => _likeController!.reverse());
    }

    if (_overlayController != null) {
      _overlayController!.reset();
      _overlayController!.forward();
    }
  }

  void _triggerLikeButtonPress() {
    widget.onLikePressed();
    if (_likeController != null) {
      _likeController!.forward().then((_) => _likeController!.reverse());
    }
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

  Widget _buildLikeOverlay() {
    return Positioned.fill(
      child: Center(
        child: AnimatedBuilder(
          animation: _overlayController!,
          builder: (context, child) {
            return Opacity(
              opacity: _overlayOpacity.value,
              child: Transform.scale(
                scale: _overlayScale.value,
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 85,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 10,
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
      onVisibilityChanged: _onVisibilityChanged,
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
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onProfileTapped,
                    // --- STYLE: Rounded Square Profile Pic ---
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(14),
                        image:
                            authorData['profilePhotoUrl'].isNotEmpty
                                ? DecorationImage(
                                  image: CachedNetworkImageProvider(
                                    authorData['profilePhotoUrl'],
                                  ),
                                  fit: BoxFit.cover,
                                )
                                : null,
                      ),
                      child:
                          authorData['profilePhotoUrl'].isEmpty
                              ? const Icon(
                                Icons.person,
                                color: Colors.grey,
                                size: 24,
                              )
                              : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorData['displayName'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
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
                            // Optional: Display location if you have it in data
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

            // --- MEDIA CONTENT (WITH DEEP CURVE) ---
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: ClipRRect(
                        // --- STYLE: Deep Curve ---
                        borderRadius: BorderRadius.circular(30),
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
                            _buildLikeOverlay(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else if (mediaUrls.isNotEmpty)
              Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.width,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: ClipRRect(
                        // --- STYLE: Deep Curve ---
                        borderRadius: BorderRadius.circular(30),
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
                                  child: CachedNetworkImage(
                                    imageUrl: getOptimizedCloudinaryUrl(
                                      mediaUrls[index],
                                    ),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
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
                                );
                              },
                            ),
                            _buildAudioControl(musicPreviewUrl),
                            _buildLikeOverlay(),
                          ],
                        ),
                      ),
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
                          const SizedBox(width: 8),
                          // Like Button
                          GestureDetector(
                            onTap: _triggerLikeButtonPress,
                            child: ScaleTransition(
                              scale: _likeScaleAnimation,
                              child: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.black87,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),

                          // --- COMMENT BUTTON (Opens Sheet) ---
                          GestureDetector(
                            onTap: () => _showCommentsSheet(context),
                            child: const Icon(
                              Icons.mode_comment_outlined,
                              color: Colors.black87,
                              size: 26,
                            ),
                          ),

                          const SizedBox(width: 18),
                          // Share Button
                          GestureDetector(
                            onTap: () => _onSharePressed(context),
                            child: const Icon(
                              Icons.near_me_outlined,
                              color: Colors.black87,
                              size: 26,
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
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

                  // --- View All Comments Text (Opens Sheet) ---
                  GestureDetector(
                    onTap: () => _showCommentsSheet(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        "View all comments",
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 2),
                  Text(
                    timestamp != null ? formatTimeAgo(timestamp) : '',
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

  String formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) return DateFormat('MMM d').format(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
