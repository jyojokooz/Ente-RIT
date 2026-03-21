// ===============================
// FILE NAME: profile_screen.dart
// FILE PATH: C:\Ente-RITEEE\Ente-RIT\lib\screens\pages\profile_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart'; // <-- Added Shimmer Import

import '../connections_screen.dart';
import '../edit_profile_screen.dart';
import '../chat_screen.dart';
import '../admin_panel_screen.dart';
import '../../theme_provider.dart';

import '../stories/stories_connector.dart';
import '../../models/connection_status.dart';

import '../../widgets/profile/profile_header.dart';
import '../../widgets/profile/profile_info.dart';
import '../../widgets/profile/profile_quick_access.dart';
import '../../widgets/profile/profile_posts_grid.dart';
import '../../widgets/profile/share_profile_sheet.dart';
import '../../widgets/profile/sliver_app_bar_delegate.dart';

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

  bool _isLoading = true;
  String _displayName = 'User';
  String _username = 'username';
  String _bio = '';
  String _department = '';
  String _role = 'user';
  String? _profilePhotoUrl;

  List<DocumentSnapshot> _userPosts = [];
  List<DocumentSnapshot> _taggedPosts = [];

  bool _isAdmin = false;
  bool _isPrivate = false;

  List<dynamic> _connections = [];
  ConnectionStatus _connectionStatus = ConnectionStatus.none;

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
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (_displayName == 'User') setState(() => _isLoading = true);
    try {
      final targetUserDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(targetUserId)
              .get();

      if (targetUserDoc.exists) {
        final data = targetUserDoc.data()!;
        _displayName = data['displayName'] ?? 'User';
        _username = data['username'] ?? 'username';
        _bio = data['bio'] ?? '';
        _department = data['department'] ?? '';
        _role = data['role'] ?? 'student';
        _profilePhotoUrl = data['profilePhotoUrl'];
        _isAdmin = data['isAdmin'] ?? false;
        _isPrivate = data['isPrivate'] ?? false;
        _connections = data['connections'] ?? [];
      }

      final postsQueryFuture =
          FirebaseFirestore.instance
              .collection('posts')
              .where('userId', isEqualTo: targetUserId)
              .orderBy('timestamp', descending: true)
              .get();

      final taggedPostsQueryFuture =
          FirebaseFirestore.instance
              .collection('posts')
              .where('taggedUsers', arrayContains: _username)
              .get();

      final currentUserDocFuture =
          isCurrentUser
              ? Future.value(targetUserDoc)
              : FirebaseFirestore.instance
                  .collection('users')
                  .doc(_currentUser!.uid)
                  .get();

      final results = await Future.wait([
        postsQueryFuture,
        taggedPostsQueryFuture,
        currentUserDocFuture,
      ]);

      final postsSnapshot = results[0] as QuerySnapshot<Map<String, dynamic>>;
      final taggedPostsSnapshot =
          results[1] as QuerySnapshot<Map<String, dynamic>>;
      final currentUserSnapshot =
          results[2] as DocumentSnapshot<Map<String, dynamic>>;

      if (mounted) {
        _userPosts = postsSnapshot.docs;

        _taggedPosts = taggedPostsSnapshot.docs.toList();
        _taggedPosts.sort((a, b) {
          final aTime =
              (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          final bTime =
              (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        _determineConnectionStatus(
          currentUserSnapshot.data(),
          targetUserDoc.id,
        );
        _validateAndHealConnections();
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _validateAndHealConnections() async {
    if (_connections.isEmpty) return;
    List<dynamic> validConnections = [];
    bool hasGhostUsers = false;

    for (String connId in _connections) {
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(connId)
                .get();
        if (doc.exists)
          validConnections.add(connId);
        else
          hasGhostUsers = true;
      } catch (e) {
        validConnections.add(connId);
      }
    }

    if (hasGhostUsers) {
      if (mounted) setState(() => _connections = validConnections);
      if (isCurrentUser) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .update({'connections': validConnections});
      }
    }
  }

  void _determineConnectionStatus(
    Map<String, dynamic>? currentUserData,
    String targetUserId,
  ) {
    if (isCurrentUser || currentUserData == null) {
      setState(() => _connectionStatus = ConnectionStatus.none);
      return;
    }
    final List<dynamic> connections = currentUserData['connections'] ?? [];
    final List<dynamic> sentRequests = currentUserData['sentRequests'] ?? [];
    final List<dynamic> receivedRequests =
        currentUserData['receivedRequests'] ?? [];

    if (connections.contains(targetUserId))
      _connectionStatus = ConnectionStatus.connected;
    else if (sentRequests.contains(targetUserId))
      _connectionStatus = ConnectionStatus.sent;
    else if (receivedRequests.contains(targetUserId))
      _connectionStatus = ConnectionStatus.received;
    else
      _connectionStatus = ConnectionStatus.none;
    setState(() {});
  }

  void _scrollToPosts() {
    _scrollController.animateTo(
      MediaQuery.of(context).size.height * 0.45,
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No recent stories'),
              duration: Duration(milliseconds: 1500),
            ),
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

  void _viewMingles() {
    if (isCurrentUser || _connectionStatus == ConnectionStatus.connected) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ConnectionsScreen(
                title:
                    isCurrentUser ? 'Your Mingles' : '$_displayName\'s Mingles',
                userIds: _connections,
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
    _loadAllData();
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
      setState(() => _isPrivate = isPrivate);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update privacy: $e')));
      }
    }
  }

  void _showShareProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ShareProfileSheet(
            userId: targetUserId,
            username: _username,
            displayName: _displayName,
            profilePhotoUrl: _profilePhotoUrl,
          ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
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
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          secondary: Icon(
                            themeProvider.isDarkMode
                                ? Icons.dark_mode
                                : Icons.light_mode,
                            color: const Color(0xFFFF9A44),
                          ),
                          value: themeProvider.isDarkMode,
                          onChanged:
                              (value) => themeProvider.toggleTheme(value),
                          activeColor: const Color(0xFFFF3E8E),
                        ),
                        SwitchListTile(
                          title: Text(
                            'Private Account',
                            style: GoogleFonts.poppins(
                              color: Theme.of(context).colorScheme.onSurface,
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
                            _isPrivate ? Icons.lock : Icons.lock_open,
                            color: const Color(0xFF00C6FB),
                          ),
                          value: _isPrivate,
                          onChanged: (value) {
                            setModalState(() => _isPrivate = value);
                            _togglePrivacy(value);
                          },
                          activeColor: const Color(0xFFFF3E8E),
                        ),
                        Divider(color: Theme.of(context).dividerColor),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: Text(
                            'Log Out',
                            style: GoogleFonts.poppins(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _logout();
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

  void _handleBackNavigation() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/auth-gate',
        (route) => false,
      );
    }
  }

  // --- NEW SHIMMER SKELETON METHOD ---
  Widget _buildShimmerSkeleton(bool isDark, Color bgColor) {
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade600 : Colors.grey.shade100;
    final blockColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Mock Avatar
                CircleAvatar(radius: 55, backgroundColor: blockColor),
                const SizedBox(height: 16),
                // Mock Name
                Container(
                  height: 24,
                  width: 160,
                  decoration: BoxDecoration(
                    color: blockColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Mock Username
                Container(
                  height: 16,
                  width: 100,
                  decoration: BoxDecoration(
                    color: blockColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 24),
                // Mock Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 40,
                      width: 60,
                      decoration: BoxDecoration(
                        color: blockColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 40),
                    Container(
                      height: 40,
                      width: 60,
                      decoration: BoxDecoration(
                        color: blockColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Mock Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 40,
                      width: 140,
                      decoration: BoxDecoration(
                        color: blockColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      height: 40,
                      width: 140,
                      decoration: BoxDecoration(
                        color: blockColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Mock Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Container(height: 20, width: 60, color: blockColor),
                      Container(height: 20, width: 60, color: blockColor),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Mock Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(2),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: 9,
                  itemBuilder: (_, __) => Container(color: blockColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine Theme upfront so Shimmer can use it
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedTextColor = isDark ? Colors.white54 : Colors.grey.shade600;

    // Loading State 1: Awaiting Current User
    if (_currentUser == null) {
      return _buildShimmerSkeleton(isDark, bgColor);
    }

    // Loading State 2: Awaiting Initial Profile Data Load
    if (_isLoading && _displayName == 'User') {
      return _buildShimmerSkeleton(isDark, bgColor);
    }

    bool canViewPosts =
        isCurrentUser ||
        !_isPrivate ||
        _connectionStatus == ConnectionStatus.connected;

    final isTaggedTab = _tabController.index == 1;
    final displayedPosts = isTaggedTab ? _taggedPosts : _userPosts;

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/auth-gate',
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: RefreshIndicator(
          onRefresh: _loadAllData,
          color: const Color(0xFFFF3E8E),
          backgroundColor: cardColor,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: ProfileHeader(
                  isCurrentUser: isCurrentUser,
                  isAdmin: _isAdmin,
                  profilePhotoUrl: _profilePhotoUrl,
                  bgColor: bgColor,
                  textColor: textColor,
                  isDark: isDark,
                  onBack: _handleBackNavigation,
                  onSettings: () => _showSettingsBottomSheet(context),
                  onAdminTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminPanelScreen(),
                        ),
                      ),
                  onAvatarTap: _viewStory,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
                  child: Column(
                    children: [
                      ProfileInfo(
                        displayName: _displayName,
                        username: _username,
                        department: _department,
                        bio: _bio,
                        postCount: _userPosts.length,
                        mingleCount: _connections.length,
                        isCurrentUser: isCurrentUser,
                        connectionStatus: _connectionStatus,
                        textColor: textColor,
                        mutedTextColor: mutedTextColor,
                        cardColor: cardColor,
                        onEditProfile: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          );
                          _loadAllData();
                        },
                        onShareProfile: _showShareProfileSheet,
                        onViewMingles: _viewMingles,
                        onPostCountTap: _scrollToPosts,
                        onConnectionAction: _handleConnectionAction,
                        onMessage:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => ChatScreen(
                                      receiverId: targetUserId,
                                      receiverName: _displayName,
                                      receiverImageUrl: _profilePhotoUrl ?? '',
                                    ),
                              ),
                            ),
                      ),
                      const SizedBox(height: 32),

                      if (isCurrentUser) ...[
                        ProfileQuickAccess(
                          role: _role,
                          isAdmin: _isAdmin,
                          cardColor: cardColor,
                          textColor: textColor,
                        ),
                        const SizedBox(height: 16),
                      ],
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
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      labelColor: const Color(0xFFFF3E8E),
                      unselectedLabelColor: mutedTextColor,
                      indicatorColor: const Color(0xFFFF3E8E),
                      indicatorSize: TabBarIndicatorSize.label,
                      indicatorWeight: 3,
                      labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      dividerColor: Colors.transparent,
                      tabs: const [Tab(text: "Posts"), Tab(text: "Tagged")],
                    ),
                    bgColor,
                  ),
                ),
              ProfilePostsGrid(
                userPosts: displayedPosts,
                cardColor: cardColor,
                canViewPosts: canViewPosts,
                isTaggedTab: isTaggedTab,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }
}
