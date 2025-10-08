import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// FIX 1: Corrected typo from 'package.' to 'package:'
import 'package:intl/intl.dart';

// Import the screen for posts
import 'post_detail_screen.dart';
// FIX 2: This import should now work correctly after fixing the other errors
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

    // First, mark the notification as read if it isn't already
    if (data['isRead'] == false) {
      await notificationDoc.reference.update({'isRead': true});
    }

    // Get the notification type and the related document ID
    final String? type = data['type'];
    final String? relatedDocId = data['relatedDocId'];

    // If there's no related ID, we can't navigate anywhere
    if (relatedDocId == null || relatedDocId.isEmpty) {
      return;
    }

    // Ensure the widget is still mounted before navigating
    if (!mounted) return;

    // Navigate based on the notification type
    switch (type) {
      case 'like':
      case 'comment':
        // These types relate to a post
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(postId: relatedDocId),
          ),
        );
        break;
      case 'connection_accepted':
      case 'follow': // You can handle 'follow' and 'connection' types here
        // These types relate to a user
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: relatedDocId),
          ),
        );
        break;
      default:
        // FIX 3: Removed the 'print' statement to resolve the lint warning.
        break;
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
                  // The onTap now calls our updated handler
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
                            // This will now work correctly
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
      case 'connection_accepted':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }
}
