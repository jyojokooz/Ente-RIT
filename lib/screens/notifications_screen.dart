// ===============================
// FILE NAME: notifications_screen.dart
// FILE PATH: lib/screens/notifications_screen.dart
// ===============================

// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'post_detail_screen.dart';
import 'pages/profile_screen.dart';

// Import our separated widgets
import '../widgets/notifications/empty_activity_state.dart';
import '../widgets/notifications/suggested_users_list.dart';
import '../widgets/notifications/connection_requests_header.dart';
import '../widgets/notifications/notification_tile.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  // State for suggestions is now managed here for refresh
  late Future<List<DocumentSnapshot>> _suggestedUsersFuture;

  @override
  void initState() {
    super.initState();
    _markAllAsRead();
    // Initialize the future for suggestions
    _suggestedUsersFuture = _fetchSuggestedUsers();
  }

  // --- NEW: REFRESH FUNCTION ---
  Future<void> _handleRefresh() async {
    // Re-fetch data for all dynamic parts of the screen
    final newSuggestedUsersFuture = _fetchSuggestedUsers();

    // Using setState will cause the FutureBuilder for suggestions to rebuild
    // with the new future. The StreamBuilders will automatically get new data.
    setState(() {
      _suggestedUsersFuture = newSuggestedUsersFuture;
    });

    // We can also re-mark as read, just in case a notification came in
    // while the user was on the screen.
    await _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    // Give a slight delay to avoid conflicts on initial load
    await Future.delayed(const Duration(milliseconds: 500));
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

  // This function now just fetches the data, it doesn't set state directly
  Future<List<DocumentSnapshot>> _fetchSuggestedUsers() async {
    try {
      // Fetch a different set of users on refresh for a dynamic feel
      final snap =
          await FirebaseFirestore.instance.collection('users').limit(15).get();
      return snap.docs.where((doc) => doc.id != currentUser.uid).toList();
    } catch (e) {
      return [];
    }
  }

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
      // Wrap the entire body in a RefreshIndicator
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFFFF3E8E),
        backgroundColor: cardColor,
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: currentUser.uid)
                  .orderBy('timestamp', descending: true)
                  .limit(20)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
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

            List<DocumentSnapshot> notifications = [];
            if (snapshot.hasData) {
              notifications =
                  snapshot.data!.docs
                      .where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['type'] != 'message';
                      })
                      .take(10)
                      .toList();
            }

            return CustomScrollView(
              // Add physics to ensure the refresh indicator always works
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // 1. CONNECTION REQUESTS HEADER
                SliverToBoxAdapter(
                  child: ConnectionRequestsHeader(
                    currentUser: currentUser,
                    isDark: isDark,
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                ),

                // 2. NOTIFICATIONS LIST OR EMPTY STATE
                if (notifications.isEmpty)
                  SliverToBoxAdapter(
                    child: EmptyActivityState(
                      isDark: isDark,
                      textColor: textColor,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final notification = notifications[index];
                        return NotificationTile(
                          key: ValueKey(notification.id),
                          notificationDoc: notification,
                          onTap: () => _handleNotificationTap(notification),
                          isDark: isDark,
                          cardColor: cardColor,
                          textColor: textColor,
                        );
                      }, childCount: notifications.length),
                    ),
                  ),

                // 3. USER SUGGESTIONS HEADER
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(
                          color: isDark ? Colors.white10 : Colors.black12,
                          height: 1,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Suggested for you",
                          style: GoogleFonts.poppins(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "People you may know on campus",
                          style: GoogleFonts.poppins(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. USER SUGGESTIONS HORIZONTAL LIST
                SliverToBoxAdapter(
                  child: SuggestedUsersList(
                    suggestedUsersFuture: _suggestedUsersFuture,
                    isDark: isDark,
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        ),
      ),
    );
  }
}
