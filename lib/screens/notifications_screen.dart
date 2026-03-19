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

  Future<void> _cancelSentRequest(String targetUserId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final meRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid);
      final themRef = FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId);

      batch.update(meRef, {
        'sentRequests': FieldValue.arrayRemove([targetUserId]),
      });
      batch.update(themRef, {
        'receivedRequests': FieldValue.arrayRemove([currentUser.uid]),
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request cancelled."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to cancel request: $e")));
      }
    }
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

  // --- THIS FUNCTION IS NOW USED AGAIN ---
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

            // 2. SENT REQUESTS SECTION (New)
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData)
                  return const SliverToBoxAdapter(child: SizedBox.shrink());

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                final List<dynamic> sentRequests =
                    userData['sentRequests'] ?? [];

                if (sentRequests.isEmpty)
                  return const SliverToBoxAdapter(child: SizedBox.shrink());

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Sent Requests",
                          style: GoogleFonts.poppins(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: sentRequests.length,
                            itemBuilder: (context, index) {
                              return _buildSentRequestBubble(
                                sentRequests[index],
                                isDark,
                                textColor,
                              );
                            },
                          ),
                        ),
                      ],
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

            // 4. NOTIFICATIONS LIST
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('notifications')
                      .where('userId', isEqualTo: currentUser.uid)
                      .orderBy('timestamp', descending: true)
                      .limit(10)
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
                        return data['type'] != 'message';
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
                      // --- THIS IS THE FIX: Pass all required arguments to NotificationTile ---
                      return NotificationTile(
                        key: ValueKey(notification.id),
                        notificationDoc: notification,
                        onTap: () => _handleNotificationTap(notification),
                        isDark: isDark,
                        cardColor: cardColor,
                        textColor: textColor,
                      );
                      // --- END OF FIX ---
                    }, childCount: notifications.length),
                  ),
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
                        color: isDark ? Colors.white54 : Colors.black54,
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

  Widget _buildSentRequestBubble(String userId, bool isDark, Color textColor) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final photoUrl = userData['profilePhotoUrl'] ?? '';

        return Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(userId: userId),
                          ),
                        ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      backgroundImage:
                          photoUrl.isNotEmpty
                              ? CachedNetworkImageProvider(photoUrl)
                              : null,
                      child: photoUrl.isEmpty ? const Icon(Icons.person) : null,
                    ),
                  ),
                  Positioned(
                    bottom: -5,
                    right: -5,
                    child: GestureDetector(
                      onTap: () => _cancelSentRequest(userId),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? const Color(0xFF161618)
                                  : const Color(0xFFF8F9FE),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cancel,
                          color: Colors.redAccent.shade100,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 60,
                child: Text(
                  userData['displayName']?.split(' ').first ?? 'User',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
