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

  @override
  void initState() {
    super.initState();
    // 1. Auto-clear the red dot badge when the screen is opened
    _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    try {
      final unreadQuery =
          await FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: currentUser.uid)
              .where('isRead', isEqualTo: false)
              .get();

      if (unreadQuery.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in unreadQuery.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint("Error marking notifications as read: $e");
    }
  }

  Future<void> _handleNotificationTap(DocumentSnapshot notificationDoc) async {
    final data = notificationDoc.data() as Map<String, dynamic>;

    // Safety check just in case the batch update was slow
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

          // Filter out chat/message notifications from this feed
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

// 3. Converted to a StatefulWidget with KeepAlive to fix scrolling flickers
class _NotificationTile extends StatefulWidget {
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

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  bool _isPostDeleted = false;
  String? _thumbnailUrl;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkPostStatus();
  }

  // 2. Pre-fetch post data. If it doesn't exist, hide the notification!
  Future<void> _checkPostStatus() async {
    final data = widget.notificationDoc.data() as Map<String, dynamic>;
    final type = data['type'];
    final relatedDocId = data['relatedDocId'];

    if (relatedDocId != null && (type == 'like' || type == 'comment')) {
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('posts')
                .doc(relatedDocId)
                .get();
        if (!doc.exists) {
          if (mounted) {
            setState(() {
              _isPostDeleted = true;
              _isLoading = false;
            });
          }
        } else {
          final postData = doc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _thumbnailUrl =
                  postData['postThumbnailUrl'] ?? postData['postMediaUrl'];
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // It's a connection request or follow, no post needed
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Hide immediately if loading or if the associated post was deleted
    if (_isLoading) return const SizedBox.shrink();
    if (_isPostDeleted) return const SizedBox.shrink();

    final data = widget.notificationDoc.data() as Map<String, dynamic>;
    final String type = data['type'] ?? '';
    final String body = data['body'] ?? '...';
    final bool isRead = data['isRead'] ?? false;

    final String triggeringUserId = data['triggeringUserId'] ?? '';
    final String triggeringUserAvatarUrl =
        data['triggeringUserAvatarUrl'] ?? '';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

    IconData? typeIcon;
    List<Color> gradientColors = [Colors.grey, Colors.grey];

    if (type == 'like') {
      typeIcon = Icons.favorite_rounded;
      gradientColors = [const Color(0xFFFF3E8E), const Color(0xFFFF9A44)];
    } else if (type == 'comment') {
      typeIcon = Icons.chat_bubble_rounded;
      gradientColors = [const Color(0xFF00C6FB), const Color(0xFF005BEA)];
    } else if (type == 'connection_accepted') {
      typeIcon = Icons.person_add_rounded;
      gradientColors = [const Color(0xFF43E97B), const Color(0xFF38F9D7)];
    }

    final mutedTextColor = widget.isDark ? Colors.white54 : Colors.black54;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(24),
        border:
            isRead
                ? null
                : Border.all(
                  color: const Color(0xFFFF3E8E).withOpacity(0.5),
                  width: 1.5,
                ),
        boxShadow: [
          if (!widget.isDark)
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
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                            widget.isDark
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
                              border: Border.all(
                                color: widget.cardColor,
                                width: 2,
                              ),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        body,
                        style: GoogleFonts.poppins(
                          color: widget.textColor,
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

                // Pre-fetched thumbnail means no FutureBuilder needed here anymore!
                if (_thumbnailUrl != null && _thumbnailUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: _thumbnailUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorWidget:
                          (c, u, e) => Container(
                            color:
                                widget.isDark
                                    ? Colors.white10
                                    : Colors.grey.shade200,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
