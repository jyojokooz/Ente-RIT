// ===============================
// FILE NAME: comments_sheet.dart
// FILE PATH: lib/screens/comments_sheet.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentsSheet extends StatefulWidget {
  final String postId;
  const CommentsSheet({super.key, required this.postId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  final _currentUser = FirebaseAuth.instance.currentUser!;

  // To toggle the "Post" button color
  bool _isComposing = false;

  String? _replyToCommentId;
  String? _replyToUsername;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() {
      final isNotEmpty = _commentController.text.trim().isNotEmpty;
      if (_isComposing != isNotEmpty) {
        setState(() {
          _isComposing = isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startReply(String commentId, String username) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToUsername = username;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToUsername = null;
    });
    _focusNode.unfocus();
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final isReply = _replyToCommentId != null;
    final parentId = _replyToCommentId;

    _commentController.clear();
    _cancelReply();

    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId);

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUser.uid)
              .get();
      final userData = userDoc.data() ?? {};

      final newCommentData = {
        'text': text,
        'userName': userData['displayName'] ?? 'User',
        'userImageUrl': userData['profilePhotoUrl'] ?? '',
        'userId': _currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'isReply': isReply,
        'parentId': isReply ? parentId : null,
        'likes': [],
      };

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postSnapshot = await transaction.get(postRef);
        if (!postSnapshot.exists) return;

        transaction.update(postRef, {'comments': FieldValue.increment(1)});
        transaction.set(postRef.collection('comments').doc(), newCommentData);
      });

      // Notification Logic
      final postDoc = await postRef.get();
      final postData = postDoc.data() ?? {};
      final postAuthorId = postData['userId'];

      if (postAuthorId != null && postAuthorId != _currentUser.uid) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': postAuthorId,
          'title': 'New Comment',
          'body':
              '${userData['displayName'] ?? 'Someone'} commented on your post.',
          'type': 'comment',
          'relatedDocId': widget.postId,
          'triggeringUserId': _currentUser.uid,
          'triggeringUserName': userData['displayName'] ?? 'Someone',
          'triggeringUserAvatarUrl': userData['profilePhotoUrl'] ?? '',
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Error posting comment: $e");
    }
  }

  Future<void> _toggleCommentLike(
    String commentId,
    List<dynamic> currentLikes,
  ) async {
    final commentRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId);

    final uid = _currentUser.uid;

    if (currentLikes.contains(uid)) {
      await commentRef.update({
        'likes': FieldValue.arrayRemove([uid]),
      });
    } else {
      await commentRef.update({
        'likes': FieldValue.arrayUnion([uid]),
      });
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId);
    await postRef.collection('comments').doc(commentId).delete();
    await postRef.update({'comments': FieldValue.increment(-1)});
  }

  @override
  Widget build(BuildContext context) {
    // FIX 1: REMOVED MediaQuery.of(context).viewInsets.bottom logic from here.
    // The parent (showModalBottomSheet builder in post_card.dart) handles the push up.

    return Container(
      // We limit height to 90% of screen so it doesn't cover top bar
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // --- Handle Bar ---
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // --- Header ---
          Text(
            "Comments",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),

          // --- Comments List ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  );
                }

                final allDocs = snapshot.data?.docs ?? [];
                final parentComments =
                    allDocs
                        .where((doc) => (doc.data() as Map)['isReply'] != true)
                        .toList();
                final replies =
                    allDocs
                        .where((doc) => (doc.data() as Map)['isReply'] == true)
                        .toList();

                if (parentComments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "No comments yet.",
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Start the conversation.",
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    top: 16,
                    left: 16,
                    right: 16,
                    bottom: 20,
                  ),
                  itemCount: parentComments.length,
                  itemBuilder: (context, index) {
                    final parentDoc = parentComments[index];
                    final parentData = parentDoc.data() as Map<String, dynamic>;

                    final myReplies =
                        replies
                            .where(
                              (r) =>
                                  (r.data() as Map)['parentId'] == parentDoc.id,
                            )
                            .toList();
                    myReplies.sort((a, b) {
                      final t1 =
                          ((a.data() as Map)['timestamp'] as Timestamp?)
                              ?.toDate() ??
                          DateTime.now();
                      final t2 =
                          ((b.data() as Map)['timestamp'] as Timestamp?)
                              ?.toDate() ??
                          DateTime.now();
                      return t1.compareTo(t2);
                    });

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SheetCommentRow(
                          doc: parentDoc,
                          currentUserId: _currentUser.uid,
                          onReply:
                              () => _startReply(
                                parentDoc.id,
                                parentData['userName'] ?? 'User',
                              ),
                          onDelete: () => _deleteComment(parentDoc.id),
                          onLike:
                              () => _toggleCommentLike(
                                parentDoc.id,
                                parentData['likes'] ?? [],
                              ),
                        ),
                        if (myReplies.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 54.0,
                              bottom: 12,
                            ),
                            child: Column(
                              children:
                                  myReplies.map((replyDoc) {
                                    final replyData =
                                        replyDoc.data() as Map<String, dynamic>;
                                    return _SheetCommentRow(
                                      doc: replyDoc,
                                      currentUserId: _currentUser.uid,
                                      onReply:
                                          () => _startReply(
                                            parentDoc.id,
                                            replyData['userName'] ?? 'User',
                                          ),
                                      onDelete:
                                          () => _deleteComment(replyDoc.id),
                                      onLike:
                                          () => _toggleCommentLike(
                                            replyDoc.id,
                                            replyData['likes'] ?? [],
                                          ),
                                      isSmall: true,
                                    );
                                  }).toList(),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // --- Input Area (Fixed at Bottom) ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyToUsername != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Replying to $_replyToUsername",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        GestureDetector(
                          onTap: _cancelReply,
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    // FIX 2: StreamBuilder for YOUR avatar.
                    // This fetches the image from Firestore in real-time, fixing the "J" issue.
                    StreamBuilder<DocumentSnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(_currentUser.uid)
                              .snapshots(),
                      builder: (context, snapshot) {
                        String? photoUrl;
                        if (snapshot.hasData && snapshot.data!.exists) {
                          photoUrl =
                              (snapshot.data!.data()
                                  as Map<String, dynamic>)['profilePhotoUrl'];
                        }

                        // Fallback order: Firestore -> Auth -> Asset
                        photoUrl ??= _currentUser.photoURL;

                        return CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              (photoUrl != null && photoUrl.isNotEmpty)
                                  ? CachedNetworkImageProvider(photoUrl)
                                  : const AssetImage(
                                        'assets/default_avatar.png',
                                      )
                                      as ImageProvider,
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        focusNode: _focusNode,
                        textCapitalization: TextCapitalization.sentences,
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                        // FIX 3: Removed contentPadding manipulation that causes jumps
                        decoration: InputDecoration(
                          hintText: "Add a comment...",
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey[500],
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF1F1F1),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _isComposing ? _postComment : null,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          "Post",
                          style: GoogleFonts.poppins(
                            color:
                                _isComposing
                                    ? Colors.blueAccent
                                    : Colors.blueAccent.withOpacity(0.4),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Helper: Individual Comment Row ---
class _SheetCommentRow extends StatelessWidget {
  final DocumentSnapshot doc;
  final String currentUserId;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final VoidCallback onLike;
  final bool isSmall;

  const _SheetCommentRow({
    required this.doc,
    required this.currentUserId,
    required this.onReply,
    required this.onDelete,
    required this.onLike,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isMe = data['userId'] == currentUserId;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final timeString =
        timestamp != null
            ? timeago.format(timestamp, locale: 'en_short')
            : 'now';
    final List likes = data['likes'] ?? [];
    final bool isLiked = likes.contains(currentUserId);
    final int likeCount = likes.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isSmall ? 16 : 20,
            backgroundColor: Colors.grey[200],
            backgroundImage:
                data['userImageUrl'] != null &&
                        data['userImageUrl'].toString().isNotEmpty
                    ? CachedNetworkImageProvider(data['userImageUrl'])
                    : const AssetImage('assets/default_avatar.png')
                        as ImageProvider,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: "${data['userName']} ",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: data['text'],
                        style: const TextStyle(height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      timeString,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: onReply,
                      child: Text(
                        "Reply",
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: onDelete,
                        child: Icon(
                          Icons.delete_outline,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 8.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: onLike,
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: isLiked ? Colors.red : Colors.grey[600],
                  ),
                ),
                if (likeCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      "$likeCount",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
