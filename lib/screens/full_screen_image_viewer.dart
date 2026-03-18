// ===============================
// FILE NAME: full_screen_image_viewer.dart
// FILE PATH: lib/screens/full_screen_image_viewer.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'comments_sheet.dart';
import 'share_post_sheet.dart';

class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String heroTag;
  final String postId;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    required this.postId,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _zoomAnimationController;
  Animation<Matrix4>? _zoomAnimation;

  late AnimationController _likeController;
  late Animation<double> _likeScaleAnimation;

  double _dragY = 0.0;
  bool _isZoomed = false;
  TapDownDetails? _doubleTapDetails;

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
      if (_zoomAnimation != null) {
        _transformationController.value = _zoomAnimation!.value;
      }
    });

    _transformationController.addListener(() {
      final isZoomed =
          _transformationController.value.getMaxScaleOnAxis() > 1.0;
      if (_isZoomed != isZoomed) {
        setState(() => _isZoomed = isZoomed);
      }
    });

    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _likeController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _zoomAnimationController.dispose();
    _likeController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap(List<dynamic> currentLikes) {
    if (_isZoomed) {
      _animateZoom(Matrix4.identity());
    } else {
      // Trigger like on double tap if not already liked
      if (!currentLikes.contains(currentUserId)) {
        _toggleLike(currentLikes);
      }

      // Zoom in to the exact spot
      final position = _doubleTapDetails!.localPosition;
      const double scale = 2.5;
      final x = -position.dx * (scale - 1);
      final y = -position.dy * (scale - 1);

      final zoomedMatrix =
          Matrix4.identity()
            ..translate(x, y)
            ..scale(scale);
      _animateZoom(zoomedMatrix);
    }
  }

  void _animateZoom(Matrix4 targetMatrix) {
    _zoomAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(
      CurvedAnimation(
        parent: _zoomAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );
    _zoomAnimationController.forward(from: 0);
  }

  Future<void> _toggleLike(List<dynamic> currentLikes) async {
    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId);
    final isLiked = currentLikes.contains(currentUserId);

    if (isLiked) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([currentUserId]),
      });
    } else {
      _likeController.forward().then((_) => _likeController.reverse());
      await postRef.update({
        'likes': FieldValue.arrayUnion([currentUserId]),
      });
    }
  }

  void _openComments() {
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
    );
  }

  void _openShare() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SharePostSheet(postId: widget.postId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double opacity = (1 - (_dragY.abs() / 400)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onVerticalDragUpdate:
            _isZoomed
                ? null
                : (details) => setState(() => _dragY += details.delta.dy),
        onVerticalDragEnd:
            _isZoomed
                ? null
                : (details) {
                  if (_dragY.abs() > 100 ||
                      details.primaryVelocity!.abs() > 1000) {
                    Navigator.of(context).pop();
                  } else {
                    setState(() => _dragY = 0.0);
                  }
                },
        child: Container(
          color: Colors.black.withOpacity(opacity),
          child: Stack(
            children: [
              // --- 1. MEDIA LAYER ---
              StreamBuilder<DocumentSnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('posts')
                        .doc(widget.postId)
                        .snapshots(),
                builder: (context, snapshot) {
                  List<dynamic> likes = [];
                  if (snapshot.hasData && snapshot.data!.exists) {
                    likes = snapshot.data!.get('likes') ?? [];
                  }

                  return Center(
                    child: Transform.translate(
                      offset: Offset(0, _dragY),
                      child: Hero(
                        tag: widget.heroTag,
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          panEnabled: true,
                          scaleEnabled: true,
                          minScale: 1.0,
                          maxScale: 4.0,
                          clipBehavior: Clip.none,
                          onInteractionEnd: (_) {
                            if (_transformationController.value
                                    .getMaxScaleOnAxis() <
                                1.0) {
                              _animateZoom(Matrix4.identity());
                            }
                          },
                          child: GestureDetector(
                            onDoubleTapDown: _handleDoubleTapDown,
                            onDoubleTap: () => _handleDoubleTap(likes),
                            child: CachedNetworkImage(
                              imageUrl: widget.imageUrl,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // --- 2. TOP GRADIENT & BACK BUTTON ---
              AnimatedOpacity(
                opacity: _dragY == 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
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
                            size: 22,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // --- 3. BOTTOM OVERLAY (Reels Style) ---
              AnimatedOpacity(
                opacity: _dragY == 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 30),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: StreamBuilder<DocumentSnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('posts')
                                .doc(widget.postId)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || !snapshot.data!.exists)
                            return const SizedBox.shrink();

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
                              // Left: User Info & Caption
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundImage:
                                              CachedNetworkImageProvider(
                                                userImage,
                                              ),
                                          backgroundColor: Colors.grey.shade800,
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
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Right: Action Buttons
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
                                          "${likes.length}",
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
                                          "$commentsCount",
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
                                          "Share",
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
