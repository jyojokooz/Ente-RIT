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

    // Clear input IMMEDIATELY for better UX
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
      // Get current user details ONCE to stamp onto the comment
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

        // Update comment count
        transaction.update(postRef, {'comments': FieldValue.increment(1)});

        // Add comment
        final newCommentDocRef = commentCollectionRef.doc();
        transaction.set(newCommentDocRef, newCommentData);

        // Add Notification
        if (postAuthorId != null && postAuthorId != _currentUser.uid) {
          final newNotificationDocRef = notificationsCollectionRef.doc();
          transaction.set(newNotificationDocRef, {
            'userId': postAuthorId,
            'title': 'New Comment',
            'body':
                '${userData['displayName'] ?? 'Someone'} commented: "$text"',
            'type': 'comment',
            'relatedDocId': widget.postId,
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
            style: GoogleFonts.archivoBlack(fontSize: 20),
          ),
          content: Text(
            'Are you sure?',
            style: GoogleFonts.spaceMono(fontSize: 14),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.spaceMono(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(
                'Delete',
                style: GoogleFonts.spaceMono(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
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
          style: GoogleFonts.archivoBlack(color: brandBlack, fontSize: 22),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: brandBlack),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: brandBlack, height: 2),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Fetch comments directly. No extra filtering needed as user data is inside the comment.
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
                      style: GoogleFonts.spaceMono(color: Colors.grey),
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

                    // Use data directly from the comment document
                    final userImage = commentData['userImageUrl'] ?? '';
                    final userName = commentData['userName'] ?? 'User';
                    final timestamp =
                        (commentData['timestamp'] as Timestamp?)?.toDate();
                    final commentAuthorId = commentData['userId'];
                    final bool isAuthor = _currentUser.uid == commentAuthorId;

                    // --- NEO-BRUTALIST COMMENT CARD ---
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: brandBlack, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: brandBlack,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
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
                                          color: brandBlack,
                                        )
                                        : null,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                userName,
                                style: GoogleFonts.archivoBlack(
                                  fontSize: 14,
                                  color: brandBlack,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                timestamp != null
                                    ? timeago.format(
                                      timestamp,
                                      locale: 'en_short',
                                    )
                                    : 'Just now',
                                style: GoogleFonts.spaceMono(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                              if (isAuthor)
                                GestureDetector(
                                  onTap: () => _deleteComment(comment.id),
                                  child: const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 42.0,
                            ), // Indent text under name
                            child: Text(
                              commentData['text'] ?? '',
                              style: GoogleFonts.poppins(
                                color: brandBlack,
                                fontSize: 14,
                              ),
                            ),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: brandBlack, width: 2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: brandBlack, width: 2),
                    ),
                    child: TextField(
                      controller: _commentController,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.poppins(color: brandBlack),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: GoogleFonts.spaceMono(
                          color: Colors.grey.shade500,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _postComment,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: brandPurple,
                      shape: BoxShape.circle,
                      border: Border.all(color: brandBlack, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: brandBlack,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(
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
