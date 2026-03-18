// ===============================
// FILE NAME: comment_row.dart
// FILE PATH: lib/widgets/comments/comment_row.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentRow extends StatelessWidget {
  final DocumentSnapshot doc;
  final String currentUserId;
  final bool isDark;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final VoidCallback onLike;
  final bool isSmall;

  const CommentRow({
    super.key,
    required this.doc,
    required this.currentUserId,
    required this.isDark,
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

    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedTextColor = isDark ? Colors.white54 : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isSmall ? 14 : 18,
            backgroundColor:
                isDark ? Colors.grey.shade800 : Colors.grey.shade200,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDark ? const Color(0xFF252528) : Colors.grey.shade100,
                    borderRadius: BorderRadius.only(
                      topRight: const Radius.circular(16),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                      topLeft:
                          isSmall
                              ? const Radius.circular(16)
                              : const Radius.circular(4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['userName'] ?? 'User',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data['text'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: textColor.withOpacity(0.9),
                          height: 1.3,
                        ),
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
                        color: mutedTextColor,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: onReply,
                      child: Text(
                        "Reply",
                        style: GoogleFonts.poppins(
                          color: mutedTextColor,
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
                          color: mutedTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: onLike,
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: isLiked ? Colors.red : mutedTextColor,
                  ),
                ),
                if (likeCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "$likeCount",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: mutedTextColor,
                        fontWeight: FontWeight.w600,
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
