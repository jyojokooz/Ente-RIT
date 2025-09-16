import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Import the new screen we just created
import 'post_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;

  // --- THIS FUNCTION IS NOW UPDATED ---
  Future<void> _handleNotificationTap(DocumentSnapshot notificationDoc) async {
    final data = notificationDoc.data() as Map<String, dynamic>;

    // First, mark the notification as read
    if (data['isRead'] == false) {
      await notificationDoc.reference.update({'isRead': true});
    }

    // Then, navigate if there's a related post ID
    final String? postId = data['relatedDocId'];
    if (postId != null && postId.isNotEmpty) {
      if (mounted) {
        // Check if the widget is still in the tree
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(postId: postId),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
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
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'You have no notifications.',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            );
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;
              final bool isRead = data['isRead'] ?? false;
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

              return Card(
                color:
                    isRead
                        ? Colors.grey.shade900
                        : const Color.fromARGB(38, 255, 235, 59),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  // Call the new handler function on tap
                  onTap: () => _handleNotificationTap(notification),
                  leading: Icon(
                    _getIconForType(data['type']),
                    color: isRead ? Colors.white54 : Colors.yellow,
                  ),
                  title: Text(
                    data['title'] ?? 'Notification',
                    style: GoogleFonts.poppins(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    data['body'] ?? '',
                    style: TextStyle(
                      color: isRead ? Colors.white60 : Colors.white,
                    ),
                  ),
                  trailing:
                      timestamp != null
                          ? Text(
                            DateFormat.yMd().add_jm().format(timestamp),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white54,
                            ),
                          )
                          : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'follow':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }
}
