// ===============================
// FILE NAME: comment_input_bar.dart
// FILE PATH: lib/widgets/comments/comment_input_bar.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_project/features/posts/domain/reply_state.dart';

class CommentInputBar extends StatefulWidget {
  final String postId;
  final User currentUser;
  final ValueNotifier<ReplyState?> replyStateNotifier;
  final bool isDark;
  final Color bgColor;

  const CommentInputBar({
    super.key,
    required this.postId,
    required this.currentUser,
    required this.replyStateNotifier,
    required this.isDark,
    required this.bgColor,
  });

  @override
  State<CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends State<CommentInputBar> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isComposing = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // This listener efficiently rebuilds only the send button state, not the whole screen.
    _commentController.addListener(() {
      final isNotEmpty = _commentController.text.trim().isNotEmpty;
      if (_isComposing != isNotEmpty) {
        setState(() => _isComposing = isNotEmpty);
      }
    });

    // Listens for when the user taps "Reply" on a comment.
    widget.replyStateNotifier.addListener(_onReplyStateChanged);
  }

  void _onReplyStateChanged() {
    if (widget.replyStateNotifier.value != null) {
      // Automatically focuses the text field when a reply is initiated.
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    widget.replyStateNotifier.removeListener(_onReplyStateChanged);
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    final replyState = widget.replyStateNotifier.value;
    final isReply = replyState != null;
    final parentId = replyState?.commentId;

    _commentController.clear();
    widget.replyStateNotifier.value = null; // Clear reply state
    _focusNode.unfocus();

    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId);

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.currentUser.uid)
              .get();
      final userData = userDoc.data() ?? {};

      final newCommentData = {
        'text': text,
        'userName': userData['displayName'] ?? 'User',
        'userImageUrl': userData['profilePhotoUrl'] ?? '',
        'userId': widget.currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'isReply': isReply,
        'parentId': isReply ? parentId : null,
        'likes': [],
      };

      // Use a transaction for atomic write (update count + add comment)
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postSnapshot = await transaction.get(postRef);
        if (!postSnapshot.exists) return;
        transaction.update(postRef, {'comments': FieldValue.increment(1)});
        transaction.set(postRef.collection('comments').doc(), newCommentData);
      });

      // Send Notification to Post Author
      final postDoc = await postRef.get();
      final postAuthorId = postDoc.data()?['userId'];

      if (postAuthorId != null && postAuthorId != widget.currentUser.uid) {
        // --- FIX: Group all comments from this user on this post into ONE notification ---
        final notifId = 'comment_${widget.postId}_${widget.currentUser.uid}';

        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notifId)
            .set(
              {
                'userId': postAuthorId,
                'title': 'New Comment',
                'body':
                    '${userData['displayName'] ?? 'Someone'} commented: "$text"',
                'type': 'comment',
                'relatedDocId': widget.postId,
                'triggeringUserId': widget.currentUser.uid,
                'triggeringUserName': userData['displayName'] ?? 'Someone',
                'triggeringUserAvatarUrl': userData['profilePhotoUrl'] ?? '',
                'isRead': false,
                'timestamp': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            ); // Using merge:true overwrites the old notification
      }
    } catch (e) {
      debugPrint("Error posting comment: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputColor =
        widget.isDark ? const Color(0xFF252528) : Colors.grey.shade100;
    final textColor = widget.isDark ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.bgColor,
        border: Border(
          top: BorderSide(
            color: widget.isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply Indicator Banner
          ValueListenableBuilder<ReplyState?>(
            valueListenable: widget.replyStateNotifier,
            builder: (context, replyState, child) {
              if (replyState == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 8.0,
                  left: 8.0,
                  right: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Replying to @${replyState.username}",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFFF3E8E),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => widget.replyStateNotifier.value = null,
                      child: Icon(
                        Icons.cancel_rounded,
                        size: 18,
                        color: widget.isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Main Input Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    widget.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                backgroundImage:
                    (widget.currentUser.photoURL != null &&
                            widget.currentUser.photoURL!.isNotEmpty)
                        ? CachedNetworkImageProvider(
                          widget.currentUser.photoURL!,
                        )
                        : const AssetImage('assets/default_avatar.png')
                            as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: inputColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: widget.isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  child: TextField(
                    controller: _commentController,
                    focusNode: _focusNode,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    minLines: 1,
                    style: GoogleFonts.poppins(color: textColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      hintStyle: GoogleFonts.poppins(
                        color: widget.isDark ? Colors.white30 : Colors.black38,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Animated Post Button
              GestureDetector(
                onTap: (_isComposing && !_isSending) ? _postComment : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient:
                        _isComposing
                            ? const LinearGradient(
                              colors: [Color(0xFFFF3E8E), Color(0xFFFF9A44)],
                            )
                            : null,
                    color:
                        _isComposing
                            ? null
                            : (widget.isDark
                                ? Colors.white10
                                : Colors.grey.shade200),
                    shape: BoxShape.circle,
                  ),
                  child:
                      _isSending
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Icon(
                            Icons.send_rounded,
                            color:
                                _isComposing
                                    ? Colors.white
                                    : (widget.isDark
                                        ? Colors.white30
                                        : Colors.grey),
                            size: 20,
                          ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
