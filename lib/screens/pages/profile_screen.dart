// ===============================
// FILE NAME: profile_screen.dart
// FILE PATH: lib/screens/pages/profile_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:cached_network_image/cached_network_image.dart';

import '../admin_panel_screen.dart';
import '../connections_screen.dart';
import '../edit_profile_screen.dart';
import '../post_detail_screen.dart';
import '../chat_screen.dart';
import '../requests_screen.dart';
import '../driver_tracking_screen.dart';
import '../cafeteria_dashboard_screen.dart';
import '../marketplace_sold_history_screen.dart';
import '../../theme_provider.dart';

const String cloudinaryCloudName = "dcboqibnx";
const String cloudinaryUploadPreset = "flutter_profile_uploads";

enum ConnectionStatus { none, sent, received, connected }

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  late final String targetUserId;
  late final bool isCurrentUser;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isPickingImage = false;

  String _displayName = 'User';
  String _username = 'username';
  String _bio = '';
  String _department = '';
  String _role = 'user';
  String? _profilePhotoUrl;
  List<DocumentSnapshot> _userPosts = [];
  bool _isAdmin = false;
  List<dynamic> _connections = [];
  ConnectionStatus _connectionStatus = ConnectionStatus.none;

  late TabController _tabController;
  final cloudinary = CloudinaryPublic(
    cloudinaryCloudName,
    cloudinaryUploadPreset,
    cache: false,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    ); // Reduced to 2 tabs for cleaner look
    targetUserId = widget.userId ?? _currentUser.uid;
    isCurrentUser = targetUserId == _currentUser.uid;
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ... (Keep existing _compressImage, _loadAllData, _determineConnectionStatus, _uploadImage, _pickProfileImage, _logout, _viewConnections, _handleConnectionAction exactly the same as previously generated) ...
  // To save token space, I am including the critical UI parts below which build the actual layout:

  Future<File?> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(
      tempDir.path,
      '${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      minWidth: 1080,
      minHeight: 1080,
      quality: 85,
    );
    return result == null ? null : File(result.path);
  }

  Future<void> _loadAllData() async {
    if (_displayName == 'User') setState(() => _isLoading = true);
    try {
      final targetUserDocFuture =
          FirebaseFirestore.instance
              .collection('users')
              .doc(targetUserId)
              .get();
      final postsQueryFuture =
          FirebaseFirestore.instance
              .collection('posts')
              .where('userId', isEqualTo: targetUserId)
              .orderBy('timestamp', descending: true)
              .get();
      final currentUserDocFuture =
          isCurrentUser
              ? targetUserDocFuture
              : FirebaseFirestore.instance
                  .collection('users')
                  .doc(_currentUser.uid)
                  .get();

      final results = await Future.wait([
        targetUserDocFuture,
        postsQueryFuture,
        currentUserDocFuture,
      ]);

      final targetUserSnapshot =
          results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final postsSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final currentUserSnapshot =
          results[2] as DocumentSnapshot<Map<String, dynamic>>;

      if (mounted) {
        if (targetUserSnapshot.exists) {
          final data = targetUserSnapshot.data()!;
          _displayName = data['displayName'] ?? 'User';
          _username = data['username'] ?? 'username';
          _bio = data['bio'] ?? '';
          _department = data['department'] ?? '';
          _role = data['role'] ?? 'student';
          _profilePhotoUrl = data['profilePhotoUrl'];
          _isAdmin = data['isAdmin'] ?? false;
          _connections = data['connections'] ?? [];
          _determineConnectionStatus(
            currentUserSnapshot.data(),
            targetUserSnapshot.id,
          );
        }
        _userPosts = postsSnapshot.docs;
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  Future<void> _uploadImage(File imageFile) async {
    if (!isCurrentUser) return;
    final File? compressedImage = await _compressImage(imageFile);
    if (compressedImage == null) return;
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          compressedImage.path,
          folder: 'users/${_currentUser.uid}',
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .set({
            'profilePhotoUrl': response.secureUrl,
          }, SetOptions(merge: true));
      if (mounted) setState(() => _profilePhotoUrl = response.secureUrl);
    } catch (e) {}
  }

  Future<void> _pickProfileImage() async {
    if (!isCurrentUser || _isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) await _uploadImage(File(pickedFile.path));
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/auth-gate', (route) => false);
  }

  void _viewConnections() {
    if (isCurrentUser || _connectionStatus == ConnectionStatus.connected) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ConnectionsScreen(
                title:
                    isCurrentUser
                        ? 'Your Connections'
                        : '$_displayName\'s Connections',
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
        .doc(_currentUser.uid);
    final them = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId);

    if (action == 'send') {
      batch.update(me, {
        'sentRequests': FieldValue.arrayUnion([targetUserId]),
      });
      batch.update(them, {
        'receivedRequests': FieldValue.arrayUnion([_currentUser.uid]),
      });
    } else if (action == 'accept') {
      batch.update(me, {
        'connections': FieldValue.arrayUnion([targetUserId]),
        'receivedRequests': FieldValue.arrayRemove([targetUserId]),
      });
      batch.update(them, {
        'connections': FieldValue.arrayUnion([_currentUser.uid]),
        'sentRequests': FieldValue.arrayRemove([_currentUser.uid]),
      });
    } else if (action == 'cancel' || action == 'decline') {
      batch.update(me, {
        'sentRequests': FieldValue.arrayRemove([targetUserId]),
        'receivedRequests': FieldValue.arrayRemove([targetUserId]),
      });
      batch.update(them, {
        'receivedRequests': FieldValue.arrayRemove([_currentUser.uid]),
        'sentRequests': FieldValue.arrayRemove([_currentUser.uid]),
      });
    } else if (action == 'remove') {
      batch.update(me, {
        'connections': FieldValue.arrayRemove([targetUserId]),
      });
      batch.update(them, {
        'connections': FieldValue.arrayRemove([_currentUser.uid]),
      });
    }
    await batch.commit();
    _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Custom colors matching the design exactly
    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedTextColor = isDark ? Colors.white54 : Colors.grey.shade600;

    if (_isLoading && _displayName == 'User') {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF3E8E)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        color: const Color(0xFFFF3E8E),
        backgroundColor: cardColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Cover Image & Gradient Ring Avatar
            SliverToBoxAdapter(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cover Image / Background Fade
                  Container(
                    height: 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          isDark
                              ? Colors.black.withOpacity(0.8)
                              : Colors.grey.shade300,
                          bgColor,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (!isCurrentUser)
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_back_ios_new,
                                  color: textColor,
                                ),
                                onPressed: () => Navigator.pop(context),
                              )
                            else
                              const SizedBox(width: 48),
                            if (isCurrentUser)
                              IconButton(
                                icon: Icon(
                                  Icons.settings_outlined,
                                  color: textColor,
                                ),
                                onPressed:
                                    () => _showSettingsBottomSheet(context),
                              )
                            else
                              const SizedBox(width: 48),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Overlapping Gradient Avatar
                  Positioned(
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _pickProfileImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFF3E8E),
                              Color(0xFFFF9A44),
                            ], // Pink to Orange
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: bgColor,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.grey.shade800,
                            backgroundImage:
                                (_profilePhotoUrl != null &&
                                        _profilePhotoUrl!.isNotEmpty)
                                    ? CachedNetworkImageProvider(
                                      _profilePhotoUrl!,
                                    )
                                    : const AssetImage(
                                          'assets/default_avatar.png',
                                        )
                                        as ImageProvider,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. User Info
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
                child: Column(
                  children: [
                    Text(
                      _displayName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _department.isNotEmpty ? _department : '@$_username',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: mutedTextColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatCol(
                          _userPosts.length.toString(),
                          "Posts",
                          textColor,
                          mutedTextColor,
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: isDark ? Colors.white24 : Colors.black12,
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        GestureDetector(
                          onTap: _viewConnections,
                          child: _buildStatCol(
                            _connections.length.toString(),
                            "Connections",
                            textColor,
                            mutedTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Main Actions (Buttons)
                    _buildMainActionButtons(cardColor, textColor, isDark),
                    const SizedBox(height: 32),

                    // Quick Access / Achievements Block
                    if (isCurrentUser && (_isAdmin || _role != 'student'))
                      _buildQuickAccessBlock(
                        cardColor,
                        textColor,
                        mutedTextColor,
                      ),
                  ],
                ),
              ),
            ),

            // 3. Tab Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
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

            // 4. Content Grid
            _buildContentGrid(cardColor),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol(String val, String label, Color tColor, Color mColor) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: tColor,
          ),
        ),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: mColor)),
      ],
    );
  }

  Widget _buildMainActionButtons(
    Color cardColor,
    Color textColor,
    bool isDark,
  ) {
    if (isCurrentUser) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
                _loadAllData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: cardColor,
                foregroundColor: textColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                "Edit Profile",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF3E8E), Color(0xFFFF9A44)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ElevatedButton(
                onPressed: () {}, // Share logic
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  "Share Profile",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Logic for other users
    String primaryLabel = "Connect";
    VoidCallback? primaryAction = () => _handleConnectionAction('send');
    bool useGradient = true;

    if (_connectionStatus == ConnectionStatus.connected) {
      primaryLabel = "Message";
      primaryAction =
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
          );
    } else if (_connectionStatus == ConnectionStatus.sent) {
      primaryLabel = "Requested";
      primaryAction = () => _handleConnectionAction('cancel');
      useGradient = false;
    } else if (_connectionStatus == ConnectionStatus.received) {
      primaryLabel = "Accept";
      primaryAction = () => _handleConnectionAction('accept');
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient:
                  useGradient
                      ? const LinearGradient(
                        colors: [Color(0xFFFF3E8E), Color(0xFFFF9A44)],
                      )
                      : null,
              color: useGradient ? null : cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ElevatedButton(
              onPressed: primaryAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: useGradient ? Colors.white : textColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                primaryLabel,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        if (_connectionStatus == ConnectionStatus.connected) ...[
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleConnectionAction('remove'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cardColor,
                foregroundColor: textColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                "Disconnect",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickAccessBlock(
    Color cardColor,
    Color textColor,
    Color mutedColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: textColor),
              const SizedBox(width: 12),
              Text(
                "Achievements & Tools",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: textColor,
                ),
              ),
              const Spacer(),
              const Text("🔥 🎯", style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (_role == 'driver')
                  _buildCircleButton(
                    Icons.local_shipping_rounded,
                    const Color(0xFFFF3E8E),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DriverTrackingScreen(),
                      ),
                    ),
                  ),
                if (_role == 'cafeteria_admin')
                  _buildCircleButton(
                    Icons.fastfood_rounded,
                    const Color(0xFFFF9A44),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CafeteriaDashboardScreen(),
                      ),
                    ),
                  ),
                if (_isAdmin)
                  _buildCircleButton(
                    Icons.security_rounded,
                    const Color(0xFFB165FF),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminPanelScreen(),
                      ),
                    ),
                  ),
                _buildCircleButton(
                  Icons.person_add_rounded,
                  Colors.tealAccent.shade400,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RequestsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(
    IconData icon,
    Color iconColor,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              isDark
                  ? const Color(0xFF161618)
                  : Colors.grey.shade100, // Inner circle color
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 2,
          ),
        ),
        child: Icon(icon, color: iconColor, size: 28),
      ),
    );
  }

  Widget _buildContentGrid(Color cardColor) {
    if (_userPosts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 40,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(height: 10),
                Text(
                  "No posts yet",
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final postSnapshot = _userPosts[index];
          final data = postSnapshot.data() as Map<String, dynamic>;
          final mediaUrl =
              data['postType'] == 'video'
                  ? data['postThumbnailUrl']
                  : (data['postMediaUrl'] ?? data['postImageUrl']);

          return GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(postId: postSnapshot.id),
                  ),
                ),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (mediaUrl != null)
                      CachedNetworkImage(
                        imageUrl: mediaUrl,
                        fit: BoxFit.cover,
                        placeholder:
                            (c, u) =>
                                Container(color: Colors.grey.withOpacity(0.1)),
                        errorWidget: (c, u, e) => const Icon(Icons.error),
                      )
                    else
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF3E8E), Color(0xFFFF9A44)],
                          ),
                        ),
                      ),

                    if (data['postType'] == 'video')
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }, childCount: _userPosts.length),
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
            child: AnimatedBuilder(
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
                      onChanged: (value) => themeProvider.toggleTheme(value),
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
            ),
          ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color _bgColor;
  _SliverAppBarDelegate(this._tabBar, this._bgColor);
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: _bgColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
