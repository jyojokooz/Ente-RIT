import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PostCard extends StatefulWidget {
  final DocumentSnapshot postSnapshot;
  final Function() onCommentPressed;

  const PostCard({
    super.key,
    required this.postSnapshot,
    required this.onCommentPressed,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late Map<String, dynamic> postData;
  late List<dynamic> likesList;
  late bool isLiked;
  late int likeCount;

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _updateStateFromSnapshot();
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.postSnapshot != oldWidget.postSnapshot) {
      _updateStateFromSnapshot();
    }
  }

  void _updateStateFromSnapshot() {
    postData = widget.postSnapshot.data() as Map<String, dynamic>;

    if (postData['likes'] is List) {
      likesList = List<dynamic>.from(postData['likes']);
    } else {
      likesList = [];
    }

    likeCount = likesList.length;
    isLiked = likesList.contains(currentUserId);
  }

  Future<void> _toggleLike() async {
    // Optimistic UI update for instant feedback
    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        likeCount++;
        likesList.add(currentUserId); // Manually update local list
      } else {
        likeCount--;
        likesList.remove(currentUserId); // Manually update local list
      }
    });

    // Update Firestore in the background
    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postSnapshot.id);
    if (isLiked) {
      await postRef.update({
        'likes': FieldValue.arrayUnion([currentUserId]),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayRemove([currentUserId]),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryAccentColor = Colors.yellow;
    const Color primaryTextColor = Colors.white;
    const Color secondaryTextColor = Colors.white70;
    final Color cardBackgroundColor = Colors.grey.shade900;

    final String name = postData['userName'] ?? 'Unknown User';
    final String userImage = postData['userImageUrl'] ?? '';
    final String postImage = postData['postImageUrl'] ?? '';
    final String caption = postData['caption'] ?? '';
    final int commentCount = postData['comments'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(25.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      userImage.isNotEmpty ? NetworkImage(userImage) : null,
                  child: userImage.isEmpty ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 10),
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
              ],
            ),
            if (caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  caption,
                  style: GoogleFonts.poppins(
                    color: primaryTextColor.withAlpha(220),
                  ),
                ),
              ),
            if (postImage.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: Image.network(
                  postImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 300,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 300,
                      color: Colors.grey.shade800,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.yellow),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onCommentPressed,
                      // Make the tap area larger and more obvious
                      child: Container(
                        color:
                            Colors.transparent, // Makes the whole area tappable
                        child: Row(
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline,
                              size: 22,
                              color: secondaryTextColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              commentCount.toString(),
                              style: const TextStyle(color: secondaryTextColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      visualDensity: VisualDensity.compact, // Reduces padding
                      padding: const EdgeInsets.all(0),
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color:
                            isLiked ? primaryAccentColor : secondaryTextColor,
                      ),

                      iconSize: 24,
                      onPressed: _toggleLike,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      likeCount.toString(),
                      style: const TextStyle(color: secondaryTextColor),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.send_outlined,
                      size: 22,
                      color: secondaryTextColor,
                    ),
                    const SizedBox(width: 20),
                    Icon(
                      Icons.bookmark_border_outlined,
                      size: 22,
                      color: secondaryTextColor,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
