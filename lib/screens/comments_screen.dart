// ===============================
// FILE NAME: comments_screen.dart
// FILE PATH: lib/screens/comments_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _commentController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser!;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear();
    FocusScope.of(context).unfocus();

    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId);
    final commentCollectionRef = postRef.collection('comments');
    final notificationsCollectionRef = FirebaseFirestore.instance.collection(
      'notifications',
    );

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUser.uid)
              .get();
      final userData = userDoc.data() ?? {};

      final newCommentData = {
        'text': text,
        'userName': userData['displayName'] ?? 'A User',
        'userImageUrl': userData['profilePhotoUrl'] ?? '',
        'userId': _currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postSnapshot = await transaction.get(postRef);
        if (!postSnapshot.exists) throw Exception("Post does not exist!");

        final postData = postSnapshot.data() as Map<String, dynamic>;
        final postAuthorId = postData['userId'];

        transaction.update(postRef, {'comments': FieldValue.increment(1)});

        final newCommentDocRef = commentCollectionRef.doc();
        transaction.set(newCommentDocRef, newCommentData);

        // --- UPDATED NOTIFICATION LOGIC ---
        if (postAuthorId != null && postAuthorId != _currentUser.uid) {
          final postThumbnail =
              postData['postThumbnailUrl'] ?? postData['postMediaUrl'] ?? '';

          final newNotificationDocRef = notificationsCollectionRef.doc();
          transaction.set(newNotificationDocRef, {
            'userId': postAuthorId,
            'title':
                'New Comment', // Title is still useful for push notifications
            'body':
                '${userData['displayName'] ?? 'Someone'} commented on your post.',
            'type': 'comment',
            'relatedDocId': widget.postId,
            'triggeringUserId': _currentUser.uid,
            'triggeringUserName': userData['displayName'] ?? 'Someone',
            'triggeringUserAvatarUrl': userData['profilePhotoUrl'] ?? '',
            'postThumbnailUrl': postThumbnail,
            'isRead': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to post comment: $error")),
        );
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId);
    final commentRef = postRef.collection('comments').doc(commentId);

    final bool? didRequestDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.black, width: 2),
          ),
          title: Text(
            'Delete Comment?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            'Are you sure?',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (didRequestDelete == true) {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.delete(commentRef);
        transaction.update(postRef, {'comments': FieldValue.increment(-1)});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBlack = Colors.black;
    const Color brandPurple = Color(0xFF9983F3);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Comments',
          style: GoogleFonts.poppins(
            color: brandBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: brandBlack),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
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
                if (snapshot.hasError) {
                  return Center(child: Text("Error loading comments"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: brandPurple),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No comments yet.\nBe the first!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  );
                }

                final comments = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final commentData = comment.data() as Map<String, dynamic>;

                    final userImage = commentData['userImageUrl'] ?? '';
                    final userName = commentData['userName'] ?? 'User';
                    final timestamp =
                        (commentData['timestamp'] as Timestamp?)?.toDate();
                    final commentAuthorId = commentData['userId'];
                    final bool isAuthor = _currentUser.uid == commentAuthorId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage:
                                userImage.isNotEmpty
                                    ? NetworkImage(userImage)
                                    : null,
                            child:
                                userImage.isEmpty
                                    ? const Icon(
                                      Icons.person,
                                      size: 20,
                                      color: Colors.grey,
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '$userName ',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(text: commentData['text'] ?? ''),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timestamp != null
                                      ? timeago.format(
                                        timestamp,
                                        locale: 'en_short',
                                      )
                                      : 'Just now',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isAuthor)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () => _deleteComment(comment.id),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // --- INPUT AREA ---
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.poppins(color: brandBlack),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey.shade500,
                      ),
                      fillColor: Colors.grey.shade100,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _postComment,
                  child: const CircleAvatar(
                    radius: 22,
                    backgroundColor: brandPurple,
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
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
