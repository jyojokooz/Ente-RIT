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

    if (relatedDocId == null || relatedDocId.isEmpty) return;
    if (!mounted) return;

    switch (type) {
      case 'like':
      case 'comment':
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: relatedDocId),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBlack = Colors.black;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Activity',
          style: GoogleFonts.poppins(
            color: brandBlack,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: brandBlack),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
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
              child: CircularProgressIndicator(color: brandBlack),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No notifications yet.',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(
                notificationDoc: notification,
                onTap: () => _handleNotificationTap(notification),
              );
            },
          );
        },
      ),
    );
  }
}

// --- UPDATED NOTIFICATION TILE ---
class _NotificationTile extends StatelessWidget {
  final DocumentSnapshot notificationDoc;
  final VoidCallback onTap;

  const _NotificationTile({required this.notificationDoc, required this.onTap});

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

    // Get user info for avatar
    final String triggeringUserId = data['triggeringUserId'] ?? '';
    final String triggeringUserAvatarUrl =
        data['triggeringUserAvatarUrl'] ?? '';

    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- FIX 1: User Avatar with Navigation ---
            GestureDetector(
              onTap: () {
                if (triggeringUserId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ProfileScreen(userId: triggeringUserId),
                    ),
                  );
                }
              },
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey.shade200,
                // --- FIX 2: Default Avatar Logic ---
                backgroundImage:
                    triggeringUserAvatarUrl.isNotEmpty
                        ? CachedNetworkImageProvider(triggeringUserAvatarUrl)
                        : const AssetImage('assets/default_avatar.png')
                            as ImageProvider,
              ),
            ),
            const SizedBox(width: 12),

            // Notification Text
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(color: Colors.black, fontSize: 14),
                  children: [
                    TextSpan(text: body),
                    if (timestamp != null)
                      TextSpan(
                        text:
                            ' ${timeago.format(timestamp, locale: 'en_short')}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Post Thumbnail (if it exists)
            FutureBuilder<DocumentSnapshot?>(
              future: _getRelatedPost(type, relatedDocId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData &&
                    snapshot.data!.exists) {
                  final postData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final thumbnailUrl =
                      postData['postThumbnailUrl'] ?? postData['postMediaUrl'];

                  if (thumbnailUrl != null) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: thumbnailUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorWidget:
                            (c, u, e) => Container(color: Colors.grey.shade200),
                      ),
                    );
                  }
                }
                return const SizedBox(width: 44, height: 44);
              },
            ),
          ],
        ),
      ),
    );
  }
}
