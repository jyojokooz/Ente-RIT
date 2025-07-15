import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'full_screen_image_viewer.dart'; // <-- 1. ADD THIS IMPORT

class PostCard extends StatefulWidget {
  final DocumentSnapshot postSnapshot;
  final Function() onCommentPressed;
  final Function() onDeletePressed;
  final Function() onProfileTapped;

  const PostCard({
    super.key,
    required this.postSnapshot,
    required this.onCommentPressed,
    required this.onDeletePressed,
    required this.onProfileTapped,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  // All state variables and helper methods remain the same
  late Map<String, dynamic> postData;
  late List<dynamic> likesList;
  late bool isLiked;
  late int likeCount;
  late int commentCount;
  late bool isAuthor;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _updateStateFromSnapshot();
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateStateFromSnapshot();
  }

  void _updateStateFromSnapshot() {
    setState(() {
      postData = widget.postSnapshot.data() as Map<String, dynamic>;
      final postAuthorId = postData['userId'];
      isAuthor = currentUserId == postAuthorId;
      if (postData['likes'] is List) {
        likesList = List<dynamic>.from(postData['likes']);
      } else {
        likesList = [];
      }
      likeCount = likesList.length;
      isLiked = likesList.contains(currentUserId);
      commentCount = postData['comments'] ?? 0;
    });
  }

  Future<void> _toggleLike() async {
    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        likeCount++;
        likesList.add(currentUserId);
      } else {
        likeCount--;
        likesList.remove(currentUserId);
      }
    });
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
    final String username = postData['username'] ?? '';
    final String userImage = postData['userImageUrl'] ?? '';
    final String postImage = postData['postImageUrl'] ?? '';
    final String caption = postData['caption'] ?? '';

    final timestamp = (postData['timestamp'] as Timestamp?)?.toDate();
    final String formattedDate =
        timestamp != null
            ? DateFormat('MMM d, h:mm a').format(timestamp)
            : '...';

    // --- 2. CREATE A UNIQUE HERO TAG FOR EACH POST IMAGE ---
    final String heroTag = 'postImage-${widget.postSnapshot.id}';

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
            GestureDetector(
              onTap: widget.onProfileTapped,
              child: Container(
                color: Colors.transparent,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage:
                          userImage.isNotEmpty ? NetworkImage(userImage) : null,
                      child:
                          userImage.isEmpty ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                          if (username.isNotEmpty)
                            Text(
                              '@$username',
                              style: GoogleFonts.poppins(
                                color: secondaryTextColor,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: GoogleFonts.poppins(
                        color: secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                    if (isAuthor) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.more_horiz,
                          color: secondaryTextColor,
                        ),
                        onPressed: widget.onDeletePressed,
                      ),
                    ],
                  ],
                ),
              ),
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

            // --- 3. WRAP THE IMAGE IN A GESTUREDETECTOR AND HERO WIDGET ---
            if (postImage.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => FullScreenImageViewer(
                            imageUrl: postImage,
                            heroTag: heroTag, // Pass the unique tag
                          ),
                    ),
                  );
                },
                child: Hero(
                  tag: heroTag, // Assign the unique tag
                  child: ClipRRect(
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
                            child: CircularProgressIndicator(
                              color: Colors.yellow,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
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
                      child: Container(
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline,
                              size: 22,
                              color: secondaryTextColor,
                            ),
                            if (commentCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 5.0),
                                child: Text(
                                  commentCount.toString(),
                                  style: const TextStyle(
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(0),
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color:
                            isLiked ? primaryAccentColor : secondaryTextColor,
                      ),
                      iconSize: 24,
                      onPressed: _toggleLike,
                    ),
                    if (likeCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 2.0),
                        child: Text(
                          likeCount.toString(),
                          style: const TextStyle(color: secondaryTextColor),
                        ),
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
