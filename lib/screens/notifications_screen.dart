// ===============================
// FILE NAME: notifications_screen.dart
// FILE PATH: lib/screens/notifications_screen.dart
// ===============================

// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'post_detail_screen.dart';
import 'pages/profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;

  Future<void> _handleNotificationTap(DocumentSnapshot notificationDoc) async {
    final data = notificationDoc.data() as Map<String, dynamic>;
    if (data['isRead'] == false) {
      await notificationDoc.reference.update({'isRead': true});
    }

    final String? type = data['type'];
    final String? relatedDocId = data['relatedDocId'];

    if (!mounted) return;

    switch (type) {
      case 'like':
      case 'comment':
        if (relatedDocId == null) return;
        final postDoc =
            await FirebaseFirestore.instance
                .collection('posts')
                .doc(relatedDocId)
                .get();
        if (postDoc.exists) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(postId: relatedDocId),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("This post has been deleted.")),
          );
        }
        break;

      case 'follow':
      case 'connection_accepted':
        if (relatedDocId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: relatedDocId),
            ),
          );
        }
        break;

      // Messages are ignored here as they are filtered out of the UI
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Custom colors matching the modern design
    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Activity',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: currentUser.uid)
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF3E8E)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Something went wrong",
                style: TextStyle(color: textColor),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(isDark, textColor);
          }

          // --- FILTER OUT CHAT/MESSAGE NOTIFICATIONS ---
          final allNotifications = snapshot.data!.docs;
          final notifications =
              allNotifications.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['type'] != 'message';
              }).toList();

          if (notifications.isEmpty) {
            return _buildEmptyState(isDark, textColor);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(
                notificationDoc: notification,
                onTap: () => _handleNotificationTap(notification),
                isDark: isDark,
                cardColor: cardColor,
                textColor: textColor,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white10 : Colors.black12,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 60,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No recent activity',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When someone likes or comments on\nyour posts, it will show up here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final DocumentSnapshot notificationDoc;
  final VoidCallback onTap;
  final bool isDark;
  final Color cardColor;
  final Color textColor;

  const _NotificationTile({
    required this.notificationDoc,
    required this.onTap,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
  });

  Future<DocumentSnapshot?> _getRelatedPost(String type, String? docId) {
    if (docId != null && (type == 'like' || type == 'comment')) {
      return FirebaseFirestore.instance.collection('posts').doc(docId).get();
    }
    return Future.value(null);
  }

  @override
  Widget build(BuildContext context) {
    final data = notificationDoc.data() as Map<String, dynamic>;
    final String type = data['type'] ?? '';
    final String body = data['body'] ?? '...';
    final String? relatedDocId = data['relatedDocId'];
    final bool isRead = data['isRead'] ?? false;

    final String triggeringUserId = data['triggeringUserId'] ?? '';
    final String triggeringUserAvatarUrl =
        data['triggeringUserAvatarUrl'] ?? '';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

    IconData? typeIcon;
    List<Color> gradientColors = [Colors.grey, Colors.grey];

    if (type == 'like') {
      typeIcon = Icons.favorite_rounded;
      gradientColors = [
        const Color(0xFFFF3E8E),
        const Color(0xFFFF9A44),
      ]; // Pink/Orange
    } else if (type == 'comment') {
      typeIcon = Icons.chat_bubble_rounded;
      gradientColors = [
        const Color(0xFF00C6FB),
        const Color(0xFF005BEA),
      ]; // Blue
    } else if (type == 'connection_accepted') {
      typeIcon = Icons.person_add_rounded;
      gradientColors = [
        const Color(0xFF43E97B),
        const Color(0xFF38F9D7),
      ]; // Green
    }

    final mutedTextColor = isDark ? Colors.white54 : Colors.black54;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border:
            isRead
                ? null
                : Border.all(
                  color: const Color(0xFFFF3E8E).withOpacity(0.5),
                  width: 1.5,
                ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // User Avatar with Navigation & Action Icon
                GestureDetector(
                  onTap: () {
                    if (triggeringUserId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  ProfileScreen(userId: triggeringUserId),
                        ),
                      );
                    }
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor:
                            isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                        backgroundImage:
                            triggeringUserAvatarUrl.isNotEmpty
                                ? CachedNetworkImageProvider(
                                  triggeringUserAvatarUrl,
                                )
                                : null,
                        child:
                            triggeringUserAvatarUrl.isEmpty
                                ? Icon(Icons.person, color: mutedTextColor)
                                : null,
                      ),
                      if (typeIcon != null)
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: gradientColors),
                              border: Border.all(color: cardColor, width: 2),
                            ),
                            child: Icon(
                              typeIcon,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Notification Text & Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        body,
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 13,
                          fontWeight:
                              isRead ? FontWeight.normal : FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (timestamp != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            timeago.format(timestamp, locale: 'en_short'),
                            style: GoogleFonts.poppins(
                              color:
                                  isRead
                                      ? mutedTextColor
                                      : const Color(0xFFFF3E8E),
                              fontSize: 11,
                              fontWeight:
                                  isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Post Thumbnail (if applicable)
                if (type == 'like' || type == 'comment')
                  FutureBuilder<DocumentSnapshot?>(
                    future: _getRelatedPost(type, relatedDocId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData &&
                          snapshot.data!.exists) {
                        final postData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final thumbnailUrl =
                            postData['postThumbnailUrl'] ??
                            postData['postMediaUrl'];

                        if (thumbnailUrl != null) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: thumbnailUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorWidget:
                                  (c, u, e) => Container(
                                    color:
                                        isDark
                                            ? Colors.white10
                                            : Colors.grey.shade200,
                                  ),
                            ),
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
