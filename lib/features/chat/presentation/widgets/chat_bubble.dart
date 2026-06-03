// ===============================
// FILE NAME: chat_bubble.dart
// FILE PATH: lib/widgets/chat/chat_bubble.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:my_project/features/posts/presentation/post_detail_screen.dart';

class ChatBubble extends StatelessWidget {
  final Map<String, dynamic> messageData;
  final String messageId;
  final bool isMe;
  final bool isFirst;
  final bool isLast;
  final DateTime timestamp;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final VoidCallback onDelete;

  const ChatBubble({
    super.key,
    required this.messageData,
    required this.messageId,
    required this.isMe,
    required this.isFirst,
    required this.isLast,
    required this.timestamp,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.onDelete,
  });

  void _showOptions(BuildContext context) {
    // Only allow sender to unsend/delete the message
    if (!isMe) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161618) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 20),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    "Unsend Message",
                    style: GoogleFonts.poppins(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet
                    onDelete(); // Trigger delete callback
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = messageData['type'] ?? 'text';

    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child:
            type == 'post'
                ? _buildSharedPostBubble(context)
                : _buildTextBubble(),
      ),
    );
  }

  Widget _buildTextBubble() {
    const double radius = 20.0;
    const double smallRadius = 4.0;

    return Container(
      margin: EdgeInsets.only(
        top: isFirst ? 8 : 2,
        bottom: isLast ? 8 : 2,
        left: isMe ? 50 : 0,
        right: isMe ? 0 : 50,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? null : cardColor,
        gradient:
            isMe
                ? const LinearGradient(
                  colors: [Color(0xFF9983F3), Color(0xFFFF4B72)],
                )
                : null,
        boxShadow: [
          if (!isMe && !isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          if (isMe && !isDark)
            BoxShadow(
              color: const Color(0xFFFF4B72).withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(!isMe && !isFirst ? smallRadius : radius),
          topRight: Radius.circular(isMe && !isFirst ? smallRadius : radius),
          bottomLeft: Radius.circular(!isMe && !isLast ? smallRadius : radius),
          bottomRight: Radius.circular(isMe && !isLast ? smallRadius : radius),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            messageData['text'] ?? '',
            style: GoogleFonts.poppins(
              color: isMe ? Colors.white : textColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('h:mm a').format(timestamp),
            style: GoogleFonts.poppins(
              fontSize: 9,
              color:
                  isMe
                      ? Colors.white70
                      : (isDark ? Colors.white30 : Colors.black38),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedPostBubble(BuildContext context) {
    final String postId = messageData['postId'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(postId: postId),
          ),
        );
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance.collection('posts').doc(postId).get(),
          builder: (context, snapshot) {
            // Loading State
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 150,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF9983F3)),
                ),
              );
            }

            // Post Deleted / Unavailable State (Like Instagram)
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Container(
                height: 120,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.visibility_off_rounded,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Message unavailable",
                      style: GoogleFonts.poppins(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      "This post was deleted.",
                      style: GoogleFonts.poppins(
                        color: isDark ? Colors.white30 : Colors.black45,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Post Found State
            final post = snapshot.data!.data() as Map<String, dynamic>;
            final image =
                post['postThumbnailUrl'] ??
                post['postMediaUrl'] ??
                post['postImageUrl'];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (image != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: image,
                      height: 150,
                      width: 220,
                      fit: BoxFit.cover,
                      placeholder:
                          (c, u) => Container(
                            color: isDark ? Colors.white10 : Colors.grey[200],
                          ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: CachedNetworkImageProvider(
                          post['userImageUrl'] ?? '',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          post['userName'] ?? 'User',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
