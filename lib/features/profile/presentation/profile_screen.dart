// ===============================
// FILE NAME: profile_screen.dart
// FILE PATH: lib/features/profile/presentation/profile_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:my_project/features/admin/presentation/admin_panel_screen.dart';
import 'package:my_project/features/stories/presentation/stories_connector.dart';
import 'package:my_project/features/chat/presentation/chat_screen.dart';

// Unified Profile Connector Import
import 'package:my_project/features/profile/presentation/profile_connector.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  User? _currentUser;
  late String targetUserId;
  late bool isCurrentUser;

  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/auth-gate',
          (route) => false,
        );
      });
      return;
    }

    targetUserId = widget.userId ?? _currentUser!.uid;
    isCurrentUser = targetUserId == _currentUser!.uid;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToPosts() {
    _scrollController.animateTo(
      MediaQuery.of(context).size.height * 0.40,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _viewStory() async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));
      final timestamp = Timestamp.fromDate(yesterday);

      final snap =
          await FirebaseFirestore.instance
              .collection('stories')
              .where('userId', isEqualTo: targetUserId)
              .where('timestamp', isGreaterThan: timestamp)
              .orderBy('timestamp', descending: false)
              .get();

      if (snap.docs.isEmpty) {
        if (mounted && isCurrentUser) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StoryCreatorScreen()),
          );
        }
        return;
      }

      final stories = snap.docs.map((d) => Story.fromSnapshot(d)).toList();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StoryViewScreen(stories: stories)),
        );
      }
    } catch (e) {
      debugPrint("Failed to fetch story: $e");
    }
  }

  void _viewMingles(
    List<dynamic> connections,
    String displayName,
    ConnectionStatus status,
  ) {
    if (isCurrentUser || status == ConnectionStatus.connected) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ConnectionsScreen(
                title:
                    isCurrentUser ? 'Your Mingles' : '$displayName\'s Mingles',
                userIds: connections,
              ),
        ),
      );
    }
  }

  Future<void> _handleConnectionAction(String action) async {
    final batch = FirebaseFirestore.instance.batch();
    final me = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid);
    final them = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId);

    if (action == 'send') {
      batch.update(me, {
        'sentRequests': FieldValue.arrayUnion([targetUserId]),
      });
      batch.update(them, {
        'receivedRequests': FieldValue.arrayUnion([_currentUser!.uid]),
      });
    } else if (action == 'accept') {
      batch.update(me, {
        'connections': FieldValue.arrayUnion([targetUserId]),
        'receivedRequests': FieldValue.arrayRemove([targetUserId]),
      });
      batch.update(them, {
        'connections': FieldValue.arrayUnion([_currentUser!.uid]),
        'sentRequests': FieldValue.arrayRemove([_currentUser!.uid]),
      });
    } else if (action == 'cancel' || action == 'decline') {
      batch.update(me, {
        'sentRequests': FieldValue.arrayRemove([targetUserId]),
        'receivedRequests': FieldValue.arrayRemove([targetUserId]),
      });
      batch.update(them, {
        'receivedRequests': FieldValue.arrayRemove([_currentUser!.uid]),
        'sentRequests': FieldValue.arrayRemove([_currentUser!.uid]),
      });
    } else if (action == 'remove') {
      batch.update(me, {
        'connections': FieldValue.arrayRemove([targetUserId]),
      });
      batch.update(them, {
        'connections': FieldValue.arrayRemove([_currentUser!.uid]),
      });
    }
    await batch.commit();
  }

  ConnectionStatus _getConnectionStatus(Map<String, dynamic> myData) {
    if (isCurrentUser) return ConnectionStatus.none;
    final List<dynamic> connections = myData['connections'] ?? [];
    final List<dynamic> sentRequests = myData['sentRequests'] ?? [];
    final List<dynamic> receivedRequests = myData['receivedRequests'] ?? [];

    if (connections.contains(targetUserId)) return ConnectionStatus.connected;
    if (sentRequests.contains(targetUserId)) return ConnectionStatus.sent;
    if (receivedRequests.contains(targetUserId))
      return ConnectionStatus.received;
    return ConnectionStatus.none;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF1C1C22) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.white54 : Colors.grey.shade600;

    if (_currentUser == null) return const Scaffold();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading:
            isCurrentUser
                ? const SizedBox.shrink()
                : IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: textColor,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
        title: StreamBuilder<DocumentSnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(targetUserId)
                  .snapshots(),
          builder: (context, snapshot) {
            String username = "Profile";
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
              username = data['username'] ?? 'Profile';
            }
            return Text(
              username,
              style: GoogleFonts.poppins(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            );
          },
        ),
        actions: [
          if (isCurrentUser)
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(_currentUser!.uid)
                      .snapshots(),
              builder: (context, snapshot) {
                bool isAdmin = false;
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data =
                      snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  isAdmin = data['isAdmin'] ?? false;
                }
                return Row(
                  children: [
                    if (isAdmin)
                      IconButton(
                        icon: Icon(
                          Icons.admin_panel_settings_rounded,
                          color: textColor,
                        ),
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminPanelScreen(),
                              ),
                            ),
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.menu_rounded,
                        color: textColor,
                        size: 28,
                      ),
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(targetUserId)
                .snapshots(),
        builder: (context, targetUserSnap) {
          if (!targetUserSnap.hasData)
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF673AB7)),
            );

          final targetData =
              targetUserSnap.data!.data() as Map<String, dynamic>? ?? {};
          final displayName = targetData['displayName'] ?? 'User';
          final username = targetData['username'] ?? '';
          final profilePhotoUrl = targetData['profilePhotoUrl'] ?? '';
          final connections = targetData['connections'] ?? [];
          final isPrivate = targetData['isPrivate'] ?? false;

          return StreamBuilder<DocumentSnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(_currentUser!.uid)
                    .snapshots(),
            builder: (context, myUserSnap) {
              final myData =
                  myUserSnap.data?.data() as Map<String, dynamic>? ?? {};
              final connectionStatus = _getConnectionStatus(myData);

              return StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('posts')
                        .where('userId', isEqualTo: targetUserId)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, postsSnap) {
                  final userPosts = postsSnap.data?.docs ?? [];

                  return StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('posts')
                            .where('taggedUsers', arrayContains: username)
                            .snapshots(),
                    builder: (context, taggedSnap) {
                      final taggedPosts = taggedSnap.data?.docs.toList() ?? [];
                      bool canViewPosts =
                          isCurrentUser ||
                          !isPrivate ||
                          connectionStatus == ConnectionStatus.connected;
                      final displayedPosts =
                          _tabController.index == 1 ? taggedPosts : userPosts;

                      return CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // --- SUB-COMPONENT: Top Card ---
                                  ProfileTopCard(
                                    profilePhotoUrl: profilePhotoUrl,
                                    displayName: displayName,
                                    department: targetData['department'] ?? '',
                                    bio: targetData['bio'] ?? '',
                                    isCurrentUser: isCurrentUser,
                                    isDark: isDark,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    mutedColor: mutedColor,
                                    onViewStory: _viewStory,
                                    onEditProfile:
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    const EditProfileScreen(),
                                          ),
                                        ),
                                  ),
                                  const SizedBox(height: 16),

                                  // --- SUB-COMPONENT: Stats Row ---
                                  ProfileStatsBar(
                                    postCount: userPosts.length,
                                    mingleCount: connections.length,
                                    isDark: isDark,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    mutedColor: mutedColor,
                                    onScrollToPosts: _scrollToPosts,
                                    onViewMingles:
                                        () => _viewMingles(
                                          connections,
                                          displayName,
                                          connectionStatus,
                                        ),
                                  ),
                                  const SizedBox(height: 16),

                                  // --- SUB-COMPONENT: Action Buttons ---
                                  ProfileActionBar(
                                    isCurrentUser: isCurrentUser,
                                    connectionStatus: connectionStatus,
                                    isDark: isDark,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    onEditProfile:
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    const EditProfileScreen(),
                                          ),
                                        ),
                                    onShareProfile:
                                        () => showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder:
                                              (context) => ShareProfileSheet(
                                                userId: targetUserId,
                                                username: username,
                                                displayName: displayName,
                                                profilePhotoUrl:
                                                    profilePhotoUrl,
                                              ),
                                        ),
                                    onConnectionAction: _handleConnectionAction,
                                    onMessage:
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => ChatScreen(
                                                  receiverId: targetUserId,
                                                  receiverName: displayName,
                                                  receiverImageUrl:
                                                      profilePhotoUrl,
                                                ),
                                          ),
                                        ),
                                  ),
                                  const SizedBox(height: 16),

                                  if (isCurrentUser)
                                    ProfileQuickAccess(
                                      role: targetData['role'] ?? 'student',
                                      isAdmin: targetData['isAdmin'] ?? false,
                                      cardColor: cardColor,
                                      textColor: textColor,
                                    ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),

                          if (canViewPosts)
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: SliverAppBarDelegate(
                                TabBar(
                                  controller: _tabController,
                                  splashFactory: NoSplash.splashFactory,
                                  overlayColor: WidgetStateProperty.all(
                                    Colors.transparent,
                                  ),
                                  labelColor: textColor,
                                  unselectedLabelColor: mutedColor,
                                  indicatorColor: const Color(0xFF673AB7),
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  indicatorWeight: 3,
                                  dividerColor:
                                      isDark ? Colors.white10 : Colors.black12,
                                  labelStyle: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  tabs: const [
                                    Tab(text: "Posts"),
                                    Tab(text: "Tagged"),
                                  ],
                                ),
                                bgColor,
                              ),
                            ),

                          ProfilePostsGrid(
                            userPosts: displayedPosts,
                            cardColor: cardColor,
                            canViewPosts: canViewPosts,
                            isTaggedTab: _tabController.index == 1,
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 80)),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
