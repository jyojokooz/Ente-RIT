// ===============================
// FILE NAME: comments_screen.dart
// FILE PATH: lib/screens/comments_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  final _currentUser = FirebaseAuth.instance.currentUser!;

  String? _replyToCommentId;
  String? _replyToUsername;

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

  // --- UPDATED _postComment FUNCTION ---
  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final isReply = _replyToCommentId != null;
    final parentId = _replyToCommentId;

    _commentController.clear();
    _cancelReply();

    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    try {
      // Fetch current user data for notification
      final userDoc = await FirebaseFirestore.instance
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

      // Use a transaction to update post and create comment atomically
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postSnapshot = await transaction.get(postRef);
        if (!postSnapshot.exists) return;

        // Increment comment count on the post
        transaction.update(postRef, {'comments': FieldValue.increment(1)});
        // Add the new comment
        transaction.set(postRef.collection('comments').doc(), newCommentData);
      });

      // --- CREATE NOTIFICATION LOGIC ---
      final postDoc = await postRef.get();
      final postData = postDoc.data() ?? {};
      final postAuthorId = postData['userId'];

      // Don't notify if you comment on your own post
      if (postAuthorId != null && postAuthorId != _currentUser.uid) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': postAuthorId,
          'title': 'New Comment',
          'body': '${userData['displayName'] ?? 'Someone'} commented on your post.',
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
    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    await postRef.collection('comments').doc(commentId).delete();
    await postRef.update({'comments': FieldValue.increment(-1)});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Comments",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
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
                    allDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return (data['isReply'] ?? false) == false;
                    }).toList();

                final replies =
                    allDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return (data['isReply'] ?? false) == true;
                    }).toList();

                if (parentComments.isEmpty) {
                  return Center(
                    child: Text(
                      "No comments yet.",
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: parentComments.length,
                  itemBuilder: (context, index) {
                    final parentDoc = parentComments[index];
                    final parentData = parentDoc.data() as Map<String, dynamic>;

                    final myReplies =
                        replies.where((r) {
                          final rData = r.data() as Map<String, dynamic>;
                          return rData['parentId'] == parentDoc.id;
                        }).toList();

                    myReplies.sort((a, b) {
                      final d1 = a.data() as Map<String, dynamic>;
                      final d2 = b.data() as Map<String, dynamic>;
                      final t1 =
                          (d1['timestamp'] as Timestamp?)?.toDate() ??
                          DateTime.now();
                      final t2 =
                          (d2['timestamp'] as Timestamp?)?.toDate() ??
                          DateTime.now();
                      return t1.compareTo(t2);
                    });

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CommentRow(
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
                              left: 44.0,
                              bottom: 12,
                            ),
                            child: Column(
                              children: [
                                ...myReplies.map((replyDoc) {
                                  final replyData =
                                      replyDoc.data() as Map<String, dynamic>;
                                  return _CommentRow(
                                    doc: replyDoc,
                                    currentUserId: _currentUser.uid,
                                    onReply:
                                        () => _startReply(
                                          parentDoc.id,
                                          replyData['userName'] ?? 'User',
                                        ),
                                    onDelete: () => _deleteComment(replyDoc.id),
                                    onLike:
                                        () => _toggleCommentLike(
                                          replyDoc.id,
                                          replyData['likes'] ?? [],
                                        ),
                                    isSmall: true,
                                  );
                                }),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // --- INPUT AREA ---
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_replyToUsername != null)
                Container(
                  width: double.infinity,
                  color: Colors.grey[100],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Replying to $_replyToUsername",
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
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

              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          _currentUser.photoURL != null
                              ? CachedNetworkImageProvider(
                                _currentUser.photoURL!,
                              )
                              : const AssetImage('assets/default_avatar.png')
                                  as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        focusNode: _focusNode,
                        style: GoogleFonts.poppins(color: Colors.black),
                        decoration: InputDecoration(
                          hintText:
                              _replyToUsername != null
                                  ? "Reply to $_replyToUsername..."
                                  : "Add a comment...",
                          hintStyle: GoogleFonts.poppins(color: Colors.grey),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _postComment,
                      child: Text(
                        "Post",
                        style: GoogleFonts.poppins(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  final DocumentSnapshot doc;
  final String currentUserId;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final VoidCallback onLike;
  final bool isSmall;

  const _CommentRow({
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
            radius: isSmall ? 14 : 18,
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
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: data['text']),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      timeString,
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: onReply,
                      child: Text(
                        "Reply",
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(
                          Icons.delete_outline,
                          size: 14,
                          color: Colors.grey,
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
                    size: 14,
                    color: isLiked ? Colors.red : Colors.grey,
                  ),
                ),
                if (likeCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      "$likeCount",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey,
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