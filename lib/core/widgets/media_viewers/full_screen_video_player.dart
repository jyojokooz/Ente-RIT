// ===============================
// FILE NAME: full_screen_video_player.dart
// FILE PATH: lib/core/widgets/media_viewers/full_screen_video_player.dart
// ===============================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import 'package:my_project/features/posts/presentation/widgets/comments_sheet.dart';
import 'package:my_project/features/posts/presentation/widgets/share_post_sheet.dart';
import 'package:my_project/core/utils/video_preload_service.dart';

class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? postId; // Made Optional

  const FullScreenVideoPlayer({
    super.key,
    required this.videoUrl,
    this.postId, // Optional
  });

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;

  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  bool _isMuted = false;
  bool _isScrubbing = false;
  Timer? _hideTimer;
  double _dragY = 0.0;
  bool _isCaptionExpanded = false;

  late AnimationController _likeController;
  late Animation<double> _likeScaleAnimation;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _initializeVideo();

    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _likeController, curve: Curves.elasticOut),
    );
  }

  Future<void> _initializeVideo() async {
    try {
      var ctrl = VideoPreloadService.instance.takeController(widget.videoUrl);

      if (ctrl == null) {
        ctrl = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
          httpHeaders: {'User-Agent': 'EnteRITApp'},
        );
        await ctrl.initialize();
      }

      if (!mounted) {
        ctrl.dispose();
        return;
      }

      if (ctrl.value.hasError) {
        throw Exception(ctrl.value.errorDescription);
      }

      ctrl.setVolume(_isMuted ? 0.0 : 1.0);
      ctrl.setLooping(true);
      ctrl.play();
      ctrl.addListener(_onControllerUpdate);

      setState(() {
        _controller = ctrl;
        _isInitialized = true;
      });

      _startHideTimer();
    } catch (e) {
      debugPrint("Video Player Initialization Error: $e");
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _onControllerUpdate() {
    if (mounted && !_isScrubbing) setState(() {});
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    _likeController.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && (_controller?.value.isPlaying ?? false) && !_isScrubbing) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _togglePlayPause() {
    final ctrl = _controller;
    if (ctrl == null) return;
    setState(() {
      if (ctrl.value.isPlaying) {
        ctrl.pause();
        _showControls = true;
        _hideTimer?.cancel();
      } else {
        ctrl.play();
        _startHideTimer();
      }
    });
  }

  void _toggleMute() {
    final ctrl = _controller;
    if (ctrl == null) return;
    setState(() {
      _isMuted = !_isMuted;
      ctrl.setVolume(_isMuted ? 0.0 : 1.0);
    });
    _startHideTimer();
  }

  Future<void> _sendMingleRequest(String targetUserId) async {
    if (targetUserId == currentUserId) return;
    final batch = FirebaseFirestore.instance.batch();
    final meRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId);
    final themRef = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId);

    batch.update(meRef, {
      'sentRequests': FieldValue.arrayUnion([targetUserId]),
    });
    batch.update(themRef, {
      'receivedRequests': FieldValue.arrayUnion([currentUserId]),
    });

    try {
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request sent!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error sending request: $e");
    }
  }

  Future<void> _toggleLike(List<dynamic> currentLikes) async {
    if (widget.postId == null) return;

    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId);
    final isLiked = currentLikes.contains(currentUserId);
    final notifId = 'like_${widget.postId}_$currentUserId';

    if (isLiked) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([currentUserId]),
      });
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notifId)
          .delete();
    } else {
      _likeController.forward().then((_) => _likeController.reverse());
      await postRef.update({
        'likes': FieldValue.arrayUnion([currentUserId]),
      });

      final postSnapshot = await postRef.get();
      final postAuthorId = postSnapshot.data()?['userId'];

      if (postAuthorId != null && postAuthorId != currentUserId) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUserId)
                .get();
        final userData = userDoc.data() ?? {};

        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notifId)
            .set({
              'userId': postAuthorId,
              'title': 'New Like',
              'body':
                  '${userData['displayName'] ?? 'Someone'} liked your post.',
              'type': 'like',
              'relatedDocId': widget.postId,
              'triggeringUserId': currentUserId,
              'triggeringUserName': userData['displayName'] ?? 'User',
              'triggeringUserAvatarUrl': userData['profilePhotoUrl'] ?? '',
              'isRead': false,
              'timestamp': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    }
  }

  void _openComments() {
    if (widget.postId == null) return;
    _controller?.pause();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: CommentsSheet(postId: widget.postId!),
          ),
    ).then((_) => _controller?.play());
  }

  void _openShare() {
    if (widget.postId == null) return;
    _controller?.pause();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SharePostSheet(postId: widget.postId!),
    ).then((_) => _controller?.play());
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}m';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;
    final double opacity = (1 - (_dragY.abs() / 300)).clamp(0.0, 1.0);
    final duration =
        ctrl != null ? ctrl.value.duration.inMilliseconds.toDouble() : 0.0;
    final position =
        ctrl != null ? ctrl.value.position.inMilliseconds.toDouble() : 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: _toggleControls,
        onVerticalDragUpdate: (details) {
          setState(() {
            _dragY += details.delta.dy;
            _showControls = false;
          });
        },
        onVerticalDragEnd: (details) {
          if (_dragY.abs() > 100 || details.primaryVelocity!.abs() > 1000) {
            Navigator.of(context).pop();
          } else {
            setState(() => _dragY = 0.0);
          }
        },
        child: Container(
          color: Colors.black.withOpacity(opacity),
          child: Stack(
            children: [
              Center(
                child: Transform.translate(
                  offset: Offset(0, _dragY),
                  child:
                      _hasError
                          ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.white54,
                                size: 50,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Video unavailable",
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          )
                          : (_isInitialized && ctrl != null)
                          ? AspectRatio(
                            aspectRatio: ctrl.value.aspectRatio,
                            child: VideoPlayer(ctrl),
                          )
                          : Shimmer.fromColors(
                            baseColor: Colors.grey.shade900,
                            highlightColor: Colors.grey.shade800,
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.black,
                            ),
                          ),
                ),
              ),

              AnimatedOpacity(
                opacity: _showControls && _dragY == 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  height: 120,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (_isInitialized && ctrl != null && !ctrl.value.isPlaying)
                Center(
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),

              // Bottom Overlay
              if (widget.postId != null)
                AnimatedOpacity(
                  opacity: _dragY == 0 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 80, 12, 10),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent],
                          stops: [0.0, 1.0],
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StreamBuilder<DocumentSnapshot>(
                              stream:
                                  FirebaseFirestore.instance
                                      .collection('posts')
                                      .doc(widget.postId)
                                      .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData || !snapshot.data!.exists)
                                  return const SizedBox.shrink();

                                final postData =
                                    snapshot.data!.data()
                                        as Map<String, dynamic>;
                                final postAuthorId = postData['userId'] ?? '';
                                final likes =
                                    postData['likes'] as List<dynamic>? ?? [];
                                final isLiked = likes.contains(currentUserId);
                                final commentsCount = postData['comments'] ?? 0;
                                final userName =
                                    postData['username'] ??
                                    postData['userName'] ??
                                    'User';
                                final userImage =
                                    postData['userImageUrl'] ?? '';
                                final caption = postData['caption'] ?? '';

                                String displayCaption = caption;
                                bool isTruncated = false;
                                if (!_isCaptionExpanded && caption.isNotEmpty) {
                                  List<String> words = caption.split(' ');
                                  if (words.length > 6) {
                                    displayCaption =
                                        '${words.take(6).join(' ')}...';
                                    isTruncated = true;
                                  }
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            '@$userName',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              shadows: [
                                                const Shadow(
                                                  color: Colors.black45,
                                                  blurRadius: 4,
                                                  offset: Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (caption.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            GestureDetector(
                                              onTap:
                                                  () => setState(
                                                    () =>
                                                        _isCaptionExpanded =
                                                            !_isCaptionExpanded,
                                                  ),
                                              child: RichText(
                                                text: TextSpan(
                                                  text: displayCaption,
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    shadows: [
                                                      const Shadow(
                                                        color: Colors.black45,
                                                        blurRadius: 4,
                                                        offset: Offset(0, 1),
                                                      ),
                                                    ],
                                                  ),
                                                  children: [
                                                    if (isTruncated)
                                                      TextSpan(
                                                        text: ' more',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              color:
                                                                  Colors
                                                                      .white70,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        StreamBuilder<DocumentSnapshot>(
                                          stream:
                                              FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(currentUserId)
                                                  .snapshots(),
                                          builder: (context, userSnap) {
                                            bool canMingle = false;
                                            if (userSnap.hasData &&
                                                userSnap.data!.exists) {
                                              final myData =
                                                  userSnap.data!.data()
                                                      as Map<String, dynamic>;
                                              final connections =
                                                  myData['connections']
                                                      as List<dynamic>? ??
                                                  [];
                                              final sentReqs =
                                                  myData['sentRequests']
                                                      as List<dynamic>? ??
                                                  [];

                                              if (postAuthorId.isNotEmpty &&
                                                  postAuthorId !=
                                                      currentUserId &&
                                                  !connections.contains(
                                                    postAuthorId,
                                                  ) &&
                                                  !sentReqs.contains(
                                                    postAuthorId,
                                                  )) {
                                                canMingle = true;
                                              }
                                            }

                                            return Stack(
                                              clipBehavior: Clip.none,
                                              alignment: Alignment.center,
                                              children: [
                                                CircleAvatar(
                                                  radius: 22,
                                                  backgroundColor:
                                                      Colors.grey.shade800,
                                                  backgroundImage:
                                                      userImage.isNotEmpty
                                                          ? CachedNetworkImageProvider(
                                                            userImage,
                                                          )
                                                          : null,
                                                  child:
                                                      userImage.isEmpty
                                                          ? const Icon(
                                                            Icons.person,
                                                            color: Colors.white,
                                                          )
                                                          : null,
                                                ),
                                                if (canMingle)
                                                  Positioned(
                                                    bottom: -8,
                                                    child: GestureDetector(
                                                      onTap:
                                                          () =>
                                                              _sendMingleRequest(
                                                                postAuthorId,
                                                              ),
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                              color:
                                                                  const Color(
                                                                    0xFFFF2056,
                                                                  ),
                                                              shape:
                                                                  BoxShape
                                                                      .circle,
                                                              border: Border.all(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                width: 1.5,
                                                              ),
                                                            ),
                                                        padding:
                                                            const EdgeInsets.all(
                                                              2,
                                                            ),
                                                        child: const Icon(
                                                          Icons.add,
                                                          color: Colors.white,
                                                          size: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 24),
                                        GestureDetector(
                                          onTap: () => _toggleLike(likes),
                                          child: Column(
                                            children: [
                                              ScaleTransition(
                                                scale: _likeScaleAnimation,
                                                child: Icon(
                                                  Icons.favorite,
                                                  color:
                                                      isLiked
                                                          ? const Color(
                                                            0xFFFF2056,
                                                          )
                                                          : Colors.white,
                                                  size: 35,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatCount(likes.length),
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        GestureDetector(
                                          onTap: _openComments,
                                          child: Column(
                                            children: [
                                              const Icon(
                                                Icons.chat_bubble_rounded,
                                                color: Colors.white,
                                                size: 32,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatCount(commentsCount),
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        GestureDetector(
                                          onTap: _openShare,
                                          child: Column(
                                            children: [
                                              const Icon(
                                                Icons.reply_rounded,
                                                color: Colors.white,
                                                size: 36,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Share",
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: _togglePlayPause,
                                  child: Icon(
                                    (ctrl?.value.isPlaying ?? false)
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 2.0,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 5.0,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                            overlayRadius: 10.0,
                                          ),
                                      activeTrackColor: Colors.white,
                                      inactiveTrackColor: Colors.white30,
                                      thumbColor: Colors.white,
                                    ),
                                    child: Slider(
                                      value: position.clamp(
                                        0.0,
                                        duration > 0 ? duration : 1.0,
                                      ),
                                      min: 0.0,
                                      max: duration > 0 ? duration : 1.0,
                                      onChangeStart: (_) {
                                        setState(() => _isScrubbing = true);
                                        _hideTimer?.cancel();
                                      },
                                      onChanged: (value) {
                                        ctrl?.seekTo(
                                          Duration(milliseconds: value.toInt()),
                                        );
                                        setState(() {});
                                      },
                                      onChangeEnd: (_) {
                                        setState(() => _isScrubbing = false);
                                        _startHideTimer();
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _toggleMute,
                                  child: Icon(
                                    _isMuted
                                        ? Icons.volume_off_rounded
                                        : Icons.volume_up_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
