// ===============================
// FILE NAME: notification_tile.dart
// FILE PATH: lib/widgets/notifications/notification_tile.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:my_project/features/profile/presentation/profile_screen.dart';

class NotificationTile extends StatefulWidget {
  final DocumentSnapshot notificationDoc;
  final VoidCallback onTap;
  final bool isDark;
  final Color cardColor;
  final Color textColor;

  const NotificationTile({
    super.key,
    required this.notificationDoc,
    required this.onTap,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
  });

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile>
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading || _isPostDeleted) return const SizedBox.shrink();

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
