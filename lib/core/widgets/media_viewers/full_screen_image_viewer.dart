import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:my_project/features/posts/presentation/widgets/comments_sheet.dart';
import 'package:my_project/features/posts/presentation/widgets/share_post_sheet.dart';

class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String heroTag;
  final String? postId;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.postId,
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
  bool _isCaptionExpanded = false;

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
      if (widget.postId != null && !currentLikes.contains(currentUserId)) {
        _toggleLike(currentLikes);
      }
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
    );
  }

  void _openShare() {
    if (widget.postId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SharePostSheet(postId: widget.postId!),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}m';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
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
              StreamBuilder<DocumentSnapshot>(
                stream:
                    widget.postId != null
                        ? FirebaseFirestore.instance
                            .collection('posts')
                            .doc(widget.postId)
                            .snapshots()
                        : const Stream.empty(),
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
                            size: 24,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (widget.postId != null)
                AnimatedOpacity(
                  opacity: _dragY == 0 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 80, 12, 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.85),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 1.0],
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
                            final postAuthorId = postData['userId'] ?? '';
                            final likes =
                                postData['likes'] as List<dynamic>? ?? [];
                            final isLiked = likes.contains(currentUserId);
                            final commentsCount = postData['comments'] ?? 0;
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

                            // --- THE FIX: LIVE PROFILE FETCH ---
                            return StreamBuilder<DocumentSnapshot>(
                              stream:
                                  postAuthorId.isNotEmpty
                                      ? FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(postAuthorId)
                                          .snapshots()
                                      : const Stream.empty(),
                              builder: (context, authorSnap) {
                                String userName =
                                    postData['username'] ??
                                    postData['userName'] ??
                                    'User';
                                String userImage =
                                    postData['userImageUrl'] ?? '';

                                if (authorSnap.hasData &&
                                    authorSnap.data!.exists) {
                                  final authorData =
                                      authorSnap.data!.data()
                                          as Map<String, dynamic>;
                                  userName =
                                      authorData['username'] ??
                                      authorData['displayName'] ??
                                      userName;
                                  userImage =
                                      authorData['profilePhotoUrl'] ??
                                      userImage;
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
                                          const SizedBox(height: 12),
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
                                        const SizedBox(height: 12),
                                      ],
                                    ),
                                  ],
                                );
                              },
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
