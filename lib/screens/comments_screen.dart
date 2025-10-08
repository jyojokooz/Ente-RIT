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

    if (!userDoc.exists) return; // Guard against missing user data

    final userData = userDoc.data() as Map<String, dynamic>;

    final newCommentData = {
      'text': text,
      'userName': userData['displayName'] ?? 'A User',
      'userImageUrl': userData['profilePhotoUrl'] ?? '',
      'userId': _currentUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Clear the input field immediately for better UX
    _commentController.clear();

    // Use a transaction to ensure atomicity of all operations.
    await FirebaseFirestore.instance
        .runTransaction((transaction) async {
          // Step 1: Read the post document.
          final postSnapshot = await transaction.get(postRef);

          if (!postSnapshot.exists) {
            throw Exception("Post does not exist!");
          }
          final postData = postSnapshot.data() as Map<String, dynamic>;
          final postAuthorId = postData['userId'];

          // Step 2: Safely update the comment count.
          final currentCommentCount = postData['comments'] ?? 0;
          transaction.update(postRef, {'comments': currentCommentCount + 1});

          // Step 3: Add the new comment document.
          final newCommentDocRef = commentCollectionRef.doc();
          transaction.set(newCommentDocRef, newCommentData);

          // Only create a notification if the commenter is not the post author.
          if (postAuthorId != null && postAuthorId != _currentUser.uid) {
            final newNotificationDocRef = notificationsCollectionRef.doc();
            transaction.set(newNotificationDocRef, {
              'userId': postAuthorId, // The ID of the user to be notified
              'title': 'New Comment',
              'body':
                  '${userData['displayName'] ?? 'Someone'} commented: "$text"',
              'type': 'comment', // Helps in displaying the right icon
              'relatedDocId': widget.postId, // To navigate to the post
              'isRead': false,
              'timestamp': FieldValue.serverTimestamp(),
            });
          }
        })
        .catchError((error) {
          // Handle any errors during the transaction
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
          backgroundColor: Colors.grey.shade900,
          title: const Text('Delete Comment?'),
          content: const Text(
            'Are you sure you want to delete this comment? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
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

  // --- NEW: ASYNC FUNCTION TO FILTER COMMENTS ---
  Future<List<QueryDocumentSnapshot>> _filterComments(
    List<QueryDocumentSnapshot> rawComments,
  ) async {
    if (rawComments.isEmpty) {
      return [];
    }

    // 1. Get all unique user IDs from the comments
    final userIds =
        rawComments.map((doc) => doc['userId'] as String).toSet().toList();

    // 2. Fetch user documents for all those IDs in parallel
    final userFutures =
        userIds
            .map(
              (id) =>
                  FirebaseFirestore.instance.collection('users').doc(id).get(),
            )
            .toList();

    final userSnapshots = await Future.wait(userFutures);

    // 3. Create a Set of user IDs that actually exist
    final existingUserIds =
        userSnapshots
            .where((snap) => snap.exists)
            .map((snap) => snap.id)
            .toSet();

    // 4. Return only the comments where the author's ID is in the existing set
    return rawComments
        .where((comment) => existingUserIds.contains(comment['userId']))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Comments',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey.shade900,
      ),
      body: Column(
        children: [
          Expanded(
            // --- UPDATED WIDGET STRUCTURE ---
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
                    child: CircularProgressIndicator(color: Colors.yellow),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No comments yet.\nBe the first to comment!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                  );
                }

                // The raw list of comments from the stream
                final rawComments = snapshot.data!.docs;

                // Use a FutureBuilder to wait for our filtering to complete
                return FutureBuilder<List<QueryDocumentSnapshot>>(
                  future: _filterComments(rawComments),
                  builder: (context, filteredSnapshot) {
                    if (filteredSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      // While filtering, you can show a loader or the old list.
                      // A loader is better to avoid flicker.
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.yellow),
                      );
                    }
                    if (!filteredSnapshot.hasData ||
                        filteredSnapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'No comments to display.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.white70),
                        ),
                      );
                    }

                    // The clean, filtered list of comments
                    final comments = filteredSnapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.all(8.0),
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

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                userImage.isNotEmpty
                                    ? NetworkImage(userImage)
                                    : null,
                            child:
                                userImage.isEmpty
                                    ? const Icon(Icons.person_outline)
                                    : null,
                          ),
                          title: Row(
                            children: [
                              Text(
                                commentData['userName'] ?? 'User',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timestamp != null
                                    ? timeago.format(
                                      timestamp,
                                      locale: 'en_short',
                                    )
                                    : '',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              commentData['text'] ?? '',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withAlpha(220),
                              ),
                            ),
                          ),
                          trailing:
                              isAuthor
                                  ? IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    onPressed: () => _deleteComment(comment.id),
                                  )
                                  : null,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          _buildCommentInputField(),
        ],
      ),
    );
  }

  Widget _buildCommentInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border(
          top: BorderSide(color: Colors.grey.shade800, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.yellow),
              onPressed: _postComment,
            ),
          ],
        ),
      ),
    );
  }
}
