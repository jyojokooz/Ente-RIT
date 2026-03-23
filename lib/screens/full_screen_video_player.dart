// ===============================
// FILE NAME: full_screen_video_player.dart
// FILE PATH: lib/screens/full_screen_video_player.dart
// ===============================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'comments_sheet.dart';
import 'share_post_sheet.dart';

class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String postId;

  const FullScreenVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.postId,
  });

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer>
    with SingleTickerProviderStateMixin {
  late CachedVideoPlayerPlus _player;

  // Only assigned after initialize() completes — never accessed before then
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  bool _showControls = true;
  bool _isMuted = false;
  bool _isScrubbing = false;
  Timer? _hideTimer;
  double _dragY = 0.0;

  late AnimationController _likeController;
  late Animation<double> _likeScaleAnimation;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();

    _player = CachedVideoPlayerPlus.networkUrl(
      Uri.parse(widget.videoUrl),
      httpHeaders: {'User-Agent': 'EnteRITApp'},
    );

    _player.initialize().then((_) {
      if (!mounted) return;

      // Only assign _controller AFTER initialization is confirmed complete
      final ctrl = _player.controller;
      ctrl.setLooping(true);
      ctrl.play();
      ctrl.addListener(_onControllerUpdate);

      setState(() {
        _controller = ctrl;
        _isInitialized = true;
      });

      _startHideTimer();
    });

    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _likeController, curve: Curves.elasticOut),
    );
  }

  void _onControllerUpdate() {
    if (mounted && !_isScrubbing) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.removeListener(_onControllerUpdate);
    _player.dispose();
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

  Future<void> _toggleLike(List<dynamic> currentLikes) async {
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
      final postData = postSnapshot.data();
      final postAuthorId = postData?['userId'];

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
            child: CommentsSheet(postId: widget.postId),
          ),
    ).then((_) => _controller?.play());
  }

  void _openShare() {
    _controller?.pause();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SharePostSheet(postId: widget.postId),
    ).then((_) => _controller?.play());
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller; // local snapshot — null if not yet initialized
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
          color: Colors.black.withAlpha((opacity * 255).round()),
          child: Stack(
            children: [
              // ── Video / loading ──────────────────────────────────────────
              Center(
                child: Transform.translate(
                  offset: Offset(0, _dragY),
                  child:
                      _isInitialized && ctrl != null
                          ? AspectRatio(
                            aspectRatio: ctrl.value.aspectRatio,
                            child: VideoPlayer(ctrl),
                          )
                          : const CircularProgressIndicator(
                            color: Colors.yellow,
                          ),
                ),
              ),

              // ── Top bar (back button) ────────────────────────────────────
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

              // ── Paused overlay icon ──────────────────────────────────────
              if (_isInitialized && ctrl != null && !ctrl.value.isPlaying)
                Center(
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(102),
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

              // ── Bottom controls ──────────────────────────────────────────
              AnimatedOpacity(
                opacity: _dragY == 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 30),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Post metadata row
                          StreamBuilder<DocumentSnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('posts')
                                    .doc(widget.postId)
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || !snapshot.data!.exists) {
                                return const SizedBox.shrink();
                              }

                              final postData =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              final likes =
                                  postData['likes'] as List<dynamic>? ?? [];
                              final isLiked = likes.contains(currentUserId);
                              final commentsCount = postData['comments'] ?? 0;
                              final userName = postData['userName'] ?? 'User';
                              final userImage = postData['userImageUrl'] ?? '';
                              final caption = postData['caption'] ?? '';

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundImage:
                                                  CachedNetworkImageProvider(
                                                    userImage,
                                                  ),
                                              backgroundColor:
                                                  Colors.grey.shade800,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              userName,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (caption.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Text(
                                            caption,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white.withAlpha(
                                                230,
                                              ),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Action buttons
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () => _toggleLike(likes),
                                        child: Column(
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
                                                size: 32,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${likes.length}',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      GestureDetector(
                                        onTap: _openComments,
                                        child: Column(
                                          children: [
                                            const Icon(
                                              Icons.chat_bubble_outline_rounded,
                                              color: Colors.white,
                                              size: 30,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$commentsCount',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      GestureDetector(
                                        onTap: _openShare,
                                        child: const Column(
                                          children: [
                                            Icon(
                                              Icons.near_me_outlined,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Share',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
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

                          // Seek bar + play/mute row
                          Column(
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: _togglePlayPause,
                                    child: Icon(
                                      (ctrl?.value.isPlaying ?? false)
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    ctrl != null
                                        ? '${_formatDuration(ctrl.value.position)} / ${_formatDuration(ctrl.value.duration)}'
                                        : '00:00 / 00:00',
                                    style: GoogleFonts.robotoMono(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
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
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3.0,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 5.0,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 10.0,
                                  ),
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: Colors.yellow,
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
