import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  // This widget will wrap another widget (like an IconButton)
  final Widget child;

  const NotificationBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return child; // If no user, just show the original widget
    }

    return StreamBuilder<QuerySnapshot>(
      // Listen for notifications that are meant for me AND are unread.
      stream:
          FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: user.uid)
              .where('isRead', isEqualTo: false)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return child; // If no unread notifications, just show the original widget
        }

        // If there ARE unread notifications, wrap the child in a Stack to show a badge
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
              ),
            ),
          ],
        );
      },
    );
  }
}
