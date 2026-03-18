// ===============================
// FILE NAME: comments_sheet.dart
// FILE PATH: lib/screens/comments_sheet.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/reply_state.dart';
import '../widgets/comments/comment_row.dart';
import '../widgets/comments/comment_input_bar.dart';

class CommentsSheet extends StatefulWidget {
  final String postId;
  const CommentsSheet({super.key, required this.postId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  late Stream<QuerySnapshot> _commentsStream;
  final ValueNotifier<ReplyState?> _replyStateNotifier = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _commentsStream =
        FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .orderBy('timestamp', descending: true)
            .snapshots();
  }

  @override
  void dispose() {
    _replyStateNotifier.dispose();
    super.dispose();
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

    if (currentLikes.contains(_currentUser.uid)) {
      await commentRef.update({
        'likes': FieldValue.arrayRemove([_currentUser.uid]),
      });
    } else {
      await commentRef.update({
        'likes': FieldValue.arrayUnion([_currentUser.uid]),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161618) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return GestureDetector(
      // This ensures that tapping the dimmed background also closes the keyboard safely
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        // DraggableScrollableSheet is the key to the "Swipe down to close" feature
        body: DraggableScrollableSheet(
          initialChildSize: 0.6, // Starts at 60% height
          minChildSize: 0, // Can be closed by dragging to 0
          maxChildSize: 0.95, // Can expand to 95% height
          snap: true, // Snaps between sizes for a premium feel
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // --- Drag Handle (Visual cue for swiping) ---
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Comments",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                  ),

                  // --- Comments List ---
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _commentsStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFF3E8E),
                            ),
                          );
                        }

                        final allDocs = snapshot.data?.docs ?? [];
                        if (allDocs.isEmpty) {
                          return _buildEmptyState(isDark, textColor);
                        }

                        // Grouping Logic
                        final parentComments = <DocumentSnapshot>[];
                        final repliesMap = <String, List<DocumentSnapshot>>{};

                        for (var doc in allDocs) {
                          final data = doc.data() as Map<String, dynamic>;
                          if (data['isReply'] == true) {
                            final parentId = data['parentId'] as String;
                            repliesMap.putIfAbsent(parentId, () => []).add(doc);
                          } else {
                            parentComments.add(doc);
                          }
                        }

                        return ListView.builder(
                          // IMPORTANT: Use the scrollController from DraggableScrollableSheet
                          controller: scrollController,
                          physics:
                              const ClampingScrollPhysics(), // Prevents bouncy "refresh" gap at top
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                          itemCount: parentComments.length,
                          itemBuilder: (context, index) {
                            final parentDoc = parentComments[index];
                            final parentData =
                                parentDoc.data() as Map<String, dynamic>;
                            final myReplies = repliesMap[parentDoc.id] ?? [];

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
                                CommentRow(
                                  doc: parentDoc,
                                  currentUserId: _currentUser.uid,
                                  isDark: isDark,
                                  onReply: () {
                                    _replyStateNotifier.value = ReplyState(
                                      commentId: parentDoc.id,
                                      username:
                                          parentData['userName'] ?? 'User',
                                    );
                                  },
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
                                      bottom: 8,
                                    ),
                                    child: Column(
                                      children:
                                          myReplies.map((replyDoc) {
                                            final replyData =
                                                replyDoc.data()
                                                    as Map<String, dynamic>;
                                            return CommentRow(
                                              doc: replyDoc,
                                              currentUserId: _currentUser.uid,
                                              isDark: isDark,
                                              isSmall: true,
                                              onReply: () {
                                                _replyStateNotifier
                                                    .value = ReplyState(
                                                  commentId: parentDoc.id,
                                                  username:
                                                      replyData['userName'] ??
                                                      'User',
                                                );
                                              },
                                              onDelete:
                                                  () => _deleteComment(
                                                    replyDoc.id,
                                                  ),
                                              onLike:
                                                  () => _toggleCommentLike(
                                                    replyDoc.id,
                                                    replyData['likes'] ?? [],
                                                  ),
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

                  // --- Input Bar ---
                  CommentInputBar(
                    postId: widget.postId,
                    currentUser: _currentUser,
                    replyStateNotifier: _replyStateNotifier,
                    isDark: isDark,
                    bgColor: bgColor,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textColor) {
    return SingleChildScrollView(
      // Needs to be scrollable to allow the swipe-down-to-close gesture
      child: Container(
        height: 300,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 60,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              "No comments yet",
              style: GoogleFonts.poppins(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Be the first to share your thoughts.",
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white54 : Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
