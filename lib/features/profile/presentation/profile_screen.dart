// ===============================
// FILE NAME: profile_screen.dart
// FILE PATH: lib/features/profile/presentation/profile_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:my_project/features/profile/presentation/connections_screen.dart';
import 'package:my_project/features/profile/presentation/edit_profile_screen.dart';
import 'package:my_project/features/chat/presentation/chat_screen.dart';
import 'package:my_project/features/admin/presentation/admin_panel_screen.dart';
import 'package:my_project/core/constants/theme_provider.dart';

import 'package:my_project/features/stories/presentation/stories_connector.dart';
import 'package:my_project/features/profile/domain/connection_status.dart';

import 'package:my_project/features/profile/presentation/widgets/profile_quick_access.dart';
import 'package:my_project/features/profile/presentation/widgets/profile_posts_grid.dart';
import 'package:my_project/features/profile/presentation/widgets/share_profile_sheet.dart';
import 'package:my_project/features/profile/presentation/widgets/sliver_app_bar_delegate.dart';

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

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/auth-gate', (route) => false);
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

  Future<void> _togglePrivacy(bool isPrivate) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({'isPrivate': isPrivate});
      final postsQuery =
          await FirebaseFirestore.instance
              .collection('posts')
              .where('userId', isEqualTo: _currentUser!.uid)
              .get();
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in postsQuery.docs) {
        batch.update(doc.reference, {'isAuthorPrivate': isPrivate});
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Failed to update privacy: $e");
    }
  }

  void _showShareProfileSheet(
    String username,
    String displayName,
    String? profilePhotoUrl,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ShareProfileSheet(
            userId: targetUserId,
            username: username,
            displayName: displayName,
            profilePhotoUrl: profilePhotoUrl,
          ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context, bool isPrivate) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => SafeArea(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return AnimatedBuilder(
                  animation: themeProvider,
                  builder: (context, child) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          height: 4,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SwitchListTile(
                          title: Text(
                            'Dark Mode',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          secondary: Icon(
                            themeProvider.isDarkMode
                                ? Icons.dark_mode
                                : Icons.light_mode,
                            color: const Color(0xFF673AB7),
                          ),
                          value: themeProvider.isDarkMode,
                          onChanged:
                              (value) => themeProvider.toggleTheme(value),
                          activeThumbColor: const Color(0xFF673AB7),
                        ),
                        SwitchListTile(
                          title: Text(
                            'Private Account',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Only mingles can see your posts.',
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          secondary: Icon(
                            isPrivate ? Icons.lock : Icons.lock_open,
                            color: const Color(0xFF00C6FB),
                          ),
                          value: isPrivate,
                          onChanged: (value) {
                            setModalState(() => isPrivate = value);
                            _togglePrivacy(value);
                          },
                          activeThumbColor: const Color(0xFF673AB7),
                        ),
                        Divider(color: Theme.of(context).dividerColor),
                        ListTile(
                          leading: const Icon(
                            Icons.logout,
                            color: Colors.orange,
                          ),
                          title: Text(
                            'Log Out',
                            style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _logout();
                          },
                        ),
                        // --- PLAY STORE REQUIREMENT: DELETE ACCOUNT BUTTON ---
                        ListTile(
                          leading: const Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                          ),
                          title: Text(
                            'Delete Account',
                            style: GoogleFonts.poppins(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () async {
                            Navigator.pop(context); // close sheet
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (ctx) => AlertDialog(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.surface,
                                    title: const Text(
                                      "Delete Account?",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    content: const Text(
                                      "This action is permanent and cannot be undone. All your data will be erased.",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(ctx, false),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(ctx, true),
                                        child: const Text(
                                          "Delete Forever",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                            );

                            if (confirm == true) {
                              try {
                                await FirebaseAuth.instance.currentUser
                                    ?.delete();
                                if (context.mounted) {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/auth-gate',
                                    (route) => false,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please log out and log back in to verify your identity before deleting.",
                                      ),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                );
              },
            ),
          ),
    );
  }

  // --- HELPERS ---
  String _getAcronym(String name) {
    if (name.isEmpty) return "";
    String lowerName = name.toLowerCase();

    if (lowerName.contains("mca") || lowerName.contains("application")) {
      return "MCA";
    }
    if (lowerName.contains("computer")) return "CSE";
    if (lowerName.contains("mechanical")) return "ME";
    if (lowerName.contains("electrical") && lowerName.contains("electronics")) {
      return "EEE";
    }
    if (lowerName.contains("electronics") &&
        lowerName.contains("communication")) {
      return "ECE";
    }
    if (lowerName.contains("civil")) return "CE";
    if (lowerName.contains("architecture")) return "B.Arch";

    List<String> words = name.split(" ");
    if (words.length > 1) {
      return words.take(2).map((e) => e[0].toUpperCase()).join();
    }
    return name.substring(0, 2).toUpperCase();
  }

  ConnectionStatus _getConnectionStatus(Map<String, dynamic> myData) {
    if (isCurrentUser) return ConnectionStatus.none;
    final List<dynamic> connections = myData['connections'] ?? [];
    final List<dynamic> sentRequests = myData['sentRequests'] ?? [];
    final List<dynamic> receivedRequests = myData['receivedRequests'] ?? [];

    if (connections.contains(targetUserId)) return ConnectionStatus.connected;
    if (sentRequests.contains(targetUserId)) return ConnectionStatus.sent;
    if (receivedRequests.contains(targetUserId)) {
      return ConnectionStatus.received;
    }
    return ConnectionStatus.none;
  }

  // --- UI BUILDING ---
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
            // --- FIX: Read as map to prevent missing field crashes ---
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
                bool isPrivate = false;
                bool isAdmin = false;
                // --- FIX: Read as map to prevent missing field crashes ---
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data =
                      snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  isPrivate = data['isPrivate'] ?? false;
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
                          () => _showSettingsBottomSheet(context, isPrivate),
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
          if (!targetUserSnap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF673AB7)),
            );
          }

          final targetData =
              targetUserSnap.data!.data() as Map<String, dynamic>? ?? {};
          final displayName = targetData['displayName'] ?? 'User';
          final username = targetData['username'] ?? '';
          final bio = targetData['bio'] ?? '';
          final department = targetData['department'] ?? '';
          final profilePhotoUrl = targetData['profilePhotoUrl'] ?? '';
          final connections = targetData['connections'] ?? [];
          final isPrivate = targetData['isPrivate'] ?? false;
          final role = targetData['role'] ?? 'student';
          final isAdmin = targetData['isAdmin'] ?? false;

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
                      taggedPosts.sort((a, b) {
                        final aTime =
                            (a.data() as Map<String, dynamic>)['timestamp']
                                as Timestamp?;
                        final bTime =
                            (b.data() as Map<String, dynamic>)['timestamp']
                                as Timestamp?;
                        if (aTime == null || bTime == null) return 0;
                        return bTime.compareTo(aTime);
                      });

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
                                  // --- TOP PROFILE CARD ---
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        if (!isDark)
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.04,
                                            ),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Stack(
                                          children: [
                                            GestureDetector(
                                              onTap: _viewStory,
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  3,
                                                ),
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Color(0xFF673AB7),
                                                      Color(0xFF3F51B5),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                ),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: cardColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: CircleAvatar(
                                                    radius: 40,
                                                    backgroundColor:
                                                        isDark
                                                            ? Colors
                                                                .grey
                                                                .shade800
                                                            : Colors
                                                                .grey
                                                                .shade200,
                                                    backgroundImage:
                                                        profilePhotoUrl
                                                                .isNotEmpty
                                                            ? CachedNetworkImageProvider(
                                                              profilePhotoUrl,
                                                            )
                                                            : null,
                                                    child:
                                                        profilePhotoUrl.isEmpty
                                                            ? Icon(
                                                              Icons.person,
                                                              color: mutedColor,
                                                              size: 40,
                                                            )
                                                            : null,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (isCurrentUser)
                                              Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: GestureDetector(
                                                  onTap:
                                                      () => Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (_) =>
                                                                  const EditProfileScreen(),
                                                        ),
                                                      ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF673AB7,
                                                      ),
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: cardColor,
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.edit,
                                                      color: Colors.white,
                                                      size: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                displayName,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              if (department.isNotEmpty)
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFF673AB7,
                                                        ).withOpacity(0.15),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        _getAcronym(department),
                                                        style:
                                                            GoogleFonts.poppins(
                                                              color:
                                                                  const Color(
                                                                    0xFF673AB7,
                                                                  ),
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        department,
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 12,
                                                              color: mutedColor,
                                                            ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              const SizedBox(height: 12),
                                              if (bio.isNotEmpty)
                                                Text(
                                                  bio,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    color: textColor
                                                        .withOpacity(0.9),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // --- STATS ROW ---
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        if (!isDark)
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.04,
                                            ),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        GestureDetector(
                                          onTap: _scrollToPosts,
                                          child: _buildStatColumn(
                                            Icons.article_outlined,
                                            userPosts.length.toString(),
                                            "Posts",
                                            textColor,
                                            mutedColor,
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 40,
                                          color:
                                              isDark
                                                  ? Colors.white10
                                                  : Colors.black12,
                                        ),
                                        GestureDetector(
                                          onTap:
                                              () => _viewMingles(
                                                connections,
                                                displayName,
                                                connectionStatus,
                                              ),
                                          child: _buildStatColumn(
                                            Icons.people_outline_rounded,
                                            connections.length.toString(),
                                            "Mingles",
                                            textColor,
                                            mutedColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // --- ACTION BUTTONS ---
                                  _buildActionButtons(
                                    connectionStatus: connectionStatus,
                                    displayName: displayName,
                                    username: username,
                                    profilePhotoUrl: profilePhotoUrl,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 16),

                                  if (isCurrentUser)
                                    ProfileQuickAccess(
                                      role: role,
                                      isAdmin: isAdmin,
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

  Widget _buildStatColumn(
    IconData icon,
    String count,
    String label,
    Color textColor,
    Color mutedColor,
  ) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF673AB7), size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons({
    required ConnectionStatus connectionStatus,
    required String displayName,
    required String username,
    required String profilePhotoUrl,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
  }) {
    final outlinedButtonStyle = OutlinedButton.styleFrom(
      foregroundColor: textColor,
      backgroundColor: cardColor,
      side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );

    final filledButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF673AB7),
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );

    if (isCurrentUser) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: outlinedButtonStyle,
              icon: Icon(Icons.edit_outlined, size: 18, color: textColor),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  ),
              label: Text(
                "Edit Profile",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              style: filledButtonStyle,
              icon: const Icon(Icons.share_outlined, size: 18),
              onPressed:
                  () => _showShareProfileSheet(
                    username,
                    displayName,
                    profilePhotoUrl,
                  ),
              label: Text(
                "Share Profile",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      );
    }

    String primaryLabel = "Mingle";
    IconData primaryIcon = Icons.person_add_outlined;
    VoidCallback? primaryAction = () => _handleConnectionAction('send');
    bool isPrimaryFilled = true;

    if (connectionStatus == ConnectionStatus.connected) {
      primaryLabel = "Message";
      primaryIcon = Icons.chat_bubble_outline;
      primaryAction =
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ChatScreen(
                    receiverId: targetUserId,
                    receiverName: displayName,
                    receiverImageUrl: profilePhotoUrl,
                  ),
            ),
          );
      isPrimaryFilled = false;
    } else if (connectionStatus == ConnectionStatus.sent) {
      primaryLabel = "Requested";
      primaryIcon = Icons.access_time;
      primaryAction = () => _handleConnectionAction('cancel');
      isPrimaryFilled = false;
    } else if (connectionStatus == ConnectionStatus.received) {
      primaryLabel = "Accept";
      primaryIcon = Icons.check;
      primaryAction = () => _handleConnectionAction('accept');
    }

    return Row(
      children: [
        Expanded(
          child:
              isPrimaryFilled
                  ? ElevatedButton.icon(
                    style: filledButtonStyle,
                    onPressed: primaryAction,
                    icon: Icon(primaryIcon, size: 18),
                    label: Text(
                      primaryLabel,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  )
                  : OutlinedButton.icon(
                    style: outlinedButtonStyle,
                    onPressed: primaryAction,
                    icon: Icon(primaryIcon, size: 18),
                    label: Text(
                      primaryLabel,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
        ),
        if (connectionStatus == ConnectionStatus.connected) ...[
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              style: outlinedButtonStyle,
              icon: const Icon(Icons.person_remove_outlined, size: 18),
              onPressed: () => _handleConnectionAction('remove'),
              label: Text(
                "Disconnect",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
