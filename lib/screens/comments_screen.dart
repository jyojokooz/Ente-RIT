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

    final currentFocus = FocusScope.of(context);
    if (currentFocus.hasFocus) {
      currentFocus.unfocus();
    }

    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId);
    final commentCollectionRef = postRef.collection('comments');
    final notificationsCollectionRef = FirebaseFirestore.instance.collection(
      'notifications',
    );

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser.uid)
            .get();
    if (!userDoc.exists) return;

    final userData = userDoc.data() as Map<String, dynamic>;

    final newCommentData = {
      'text': text,
      'userName': userData['displayName'] ?? 'A User',
      'userImageUrl': userData['profilePhotoUrl'] ?? '',
      'userId': _currentUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
    };

    _commentController.clear();

    await FirebaseFirestore.instance
        .runTransaction((transaction) async {
          final postSnapshot = await transaction.get(postRef);
          if (!postSnapshot.exists) throw Exception("Post does not exist!");

          final postData = postSnapshot.data() as Map<String, dynamic>;
          final postAuthorId = postData['userId'];
          final currentCommentCount = postData['comments'] ?? 0;

          transaction.update(postRef, {'comments': currentCommentCount + 1});

          final newCommentDocRef = commentCollectionRef.doc();
          transaction.set(newCommentDocRef, newCommentData);

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
        })
        .catchError((error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to post comment: $error")),
            );
          }
        });
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

  Future<List<QueryDocumentSnapshot>> _filterComments(
    List<QueryDocumentSnapshot> rawComments,
  ) async {
    if (rawComments.isEmpty) return [];
    final userIds =
        rawComments.map((doc) => doc['userId'] as String).toSet().toList();
    final userFutures =
        userIds
            .map(
              (id) =>
                  FirebaseFirestore.instance.collection('users').doc(id).get(),
            )
            .toList();
    final userSnapshots = await Future.wait(userFutures);
    final existingUserIds =
        userSnapshots
            .where((snap) => snap.exists)
            .map((snap) => snap.id)
            .toSet();
    return rawComments
        .where((comment) => existingUserIds.contains(comment['userId']))
        .toList();
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

                final rawComments = snapshot.data!.docs;

                return FutureBuilder<List<QueryDocumentSnapshot>>(
                  future: _filterComments(rawComments),
                  builder: (context, filteredSnapshot) {
                    if (filteredSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox.shrink(); // Avoid flicker
                    }
                    if (!filteredSnapshot.hasData ||
                        filteredSnapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'No comments to display.',
                          style: GoogleFonts.spaceMono(color: Colors.grey),
                        ),
                      );
                    }

                    final comments = filteredSnapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final commentData =
                            comment.data() as Map<String, dynamic>;
                        final userImage = commentData['userImageUrl'] ?? '';
                        final timestamp =
                            (commentData['timestamp'] as Timestamp?)?.toDate();
                        final commentAuthorId = commentData['userId'];
                        final bool isAuthor =
                            _currentUser.uid == commentAuthorId;

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
                                    commentData['userName'] ?? 'User',
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
                                        : '',
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
