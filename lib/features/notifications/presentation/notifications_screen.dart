// ===============================
// FILE NAME: notifications_screen.dart
// FILE PATH: lib/screens/notifications_screen.dart
// ===============================

// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:my_project/features/posts/presentation/post_detail_screen.dart';
import 'package:my_project/features/profile/presentation/profile_screen.dart';
import 'package:my_project/features/profile/presentation/sent_requests_screen.dart';

// Import our separated widgets
import 'package:my_project/features/notifications/presentation/widgets/empty_activity_state.dart';
import 'package:my_project/features/notifications/presentation/widgets/suggested_users_list.dart';
import 'package:my_project/features/notifications/presentation/widgets/connection_requests_header.dart';
import 'package:my_project/features/notifications/presentation/widgets/notification_tile.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  late Future<List<DocumentSnapshot>> _suggestedUsersFuture;

  @override
  void initState() {
    super.initState();
    _markAllAsRead();
    _suggestedUsersFuture = _fetchSuggestedUsers();
  }

  Future<void> _handleRefresh() async {
    final newSuggestedUsersFuture = _fetchSuggestedUsers();
    setState(() {
      _suggestedUsersFuture = newSuggestedUsersFuture;
    });
    await _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
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

  Future<List<DocumentSnapshot>> _fetchSuggestedUsers() async {
    try {
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
        final String targetId = data['triggeringUserId'] ?? relatedDocId ?? '';
        if (targetId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: targetId),
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
    final subtitleColor = isDark ? Colors.white54 : Colors.grey.shade600;

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
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFFFF3E8E),
        backgroundColor: cardColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // 1. CONNECTION REQUESTS HEADER (Received)
            SliverToBoxAdapter(
              child: ConnectionRequestsHeader(
                currentUser: currentUser,
                isDark: isDark,
                cardColor: cardColor,
                textColor: textColor,
              ),
            ),

            // 2. SENT REQUESTS BUTTON TILE
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                final List<dynamic> sentRequests =
                    userData['sentRequests'] ?? [];

                if (sentRequests.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 0.0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SentRequestsScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? Colors.white10
                                        : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.send_rounded,
                                color: isDark ? Colors.white54 : Colors.black54,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Sent Requests",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    "You sent ${sentRequests.length} request${sentRequests.length > 1 ? 's' : ''}",
                                    style: GoogleFonts.poppins(
                                      color: subtitleColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // 3. RECENT ACTIVITY HEADER
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Divider(
                      color: isDark ? Colors.white10 : Colors.black12,
                      height: 1,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Recent Activity",
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. NOTIFICATIONS LIST WITH DYNAMIC CONNECTIONS FILTER
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                // Get the latest connections array to check against
                final List<dynamic> myConnections =
                    userData['connections'] ?? [];

                return StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('notifications')
                          .where('userId', isEqualTo: currentUser.uid)
                          .orderBy('timestamp', descending: true)
                          .limit(
                            15,
                          ) // Raised limit slightly since some might be filtered
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF3E8E),
                          ),
                        ),
                      );
                    }

                    List<DocumentSnapshot> notifications = [];
                    if (snapshot.hasData) {
                      notifications =
                          snapshot.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;

                            if (data['type'] == 'message') return false;

                            // --- NEW LOGIC: Hide Connection Accepted if they disconnected ---
                            if (data['type'] == 'connection_accepted') {
                              final triggeringUserId = data['triggeringUserId'];
                              if (!myConnections.contains(triggeringUserId)) {
                                return false; // Skip this notification (hides it from the list)
                              }
                            }

                            return true;
                          }).toList();
                    }

                    if (notifications.isEmpty) {
                      return SliverToBoxAdapter(
                        child: EmptyActivityState(
                          isDark: isDark,
                          textColor: textColor,
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                    );
                  },
                );
              },
            ),

            // 5. USER SUGGESTIONS HEADER
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
                        color: subtitleColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 6. USER SUGGESTIONS HORIZONTAL LIST
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
        ),
      ),
    );
  }
}
