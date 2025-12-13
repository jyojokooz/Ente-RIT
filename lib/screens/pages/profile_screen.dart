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

  // Brand Colors
  final Color _brandPurple = const Color(0xFF9983F3);
  final Color _bgGrey = const Color(0xFFF8F9FE);

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
    _tabController = TabController(length: 3, vsync: this);
    targetUserId = widget.userId ?? _currentUser.uid;
    isCurrentUser = targetUserId == _currentUser.uid;
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
      debugPrint("Error loading profile: $e");
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

    if (connections.contains(targetUserId)) {
      _connectionStatus = ConnectionStatus.connected;
    } else if (sentRequests.contains(targetUserId)) {
      _connectionStatus = ConnectionStatus.sent;
    } else if (receivedRequests.contains(targetUserId)) {
      _connectionStatus = ConnectionStatus.received;
    } else {
      _connectionStatus = ConnectionStatus.none;
    }
    setState(() {});
  }

  Future<void> _uploadImage(File imageFile) async {
    if (!isCurrentUser) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Updating profile photo...')));

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
      final downloadUrl = response.secureUrl;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .set({'profilePhotoUrl': downloadUrl}, SetOptions(merge: true));

      if (mounted) {
        setState(() => _profilePhotoUrl = downloadUrl);
      }
    } catch (e) {
      debugPrint("Upload failed: $e");
    }
  }

  Future<void> _pickProfileImage() async {
    if (!isCurrentUser) return;
    if (_isPickingImage) return;

    setState(() {
      _isPickingImage = true;
    });

    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        await _uploadImage(File(pickedFile.path));
      }
    } catch (e) {
      debugPrint("Image picker error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      /* Error */
    }
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be connected to see connections.')),
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
    if (_isLoading && _displayName == 'User') {
      return Scaffold(
        backgroundColor: _bgGrey,
        body: Center(child: CircularProgressIndicator(color: _brandPurple)),
      );
    }

    return Scaffold(
      backgroundColor: _bgGrey,
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        color: _brandPurple,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. The Curved Header & Avatar
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Header Background
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _brandPurple,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _brandPurple.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
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
                                icon: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              )
                            else
                              const SizedBox(width: 48),

                            Text(
                              "Profile",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),

                            if (isCurrentUser)
                              IconButton(
                                icon: const Icon(
                                  Icons.settings_outlined,
                                  color: Colors.white,
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

                  // Floating Avatar Card
                  Positioned(
                    top: 110,
                    child: GestureDetector(
                      onTap: _pickProfileImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade200,
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
                ],
              ),
            ),

            // 2. User Info (Name, Bio, Stats)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 65, left: 24, right: 24),
                child: Column(
                  children: [
                    Text(
                      _displayName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '@$_username',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        if (_role != 'student') ...[
                          const SizedBox(width: 6),
                          _buildRoleBadge(_role),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_bio.isNotEmpty)
                      Text(
                        _bio,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    if (_department.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _department,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Dashboard Stats Cards
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDashboardStat(
                          "Posts",
                          _userPosts.length.toString(),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: _viewConnections,
                          child: _buildDashboardStat(
                            "Connections",
                            _connections.length.toString(),
                            isInteractive: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildDashboardStat("Likes", "0"), // Placeholder
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Main Actions
                    _buildMainActionButtons(),

                    const SizedBox(height: 24),

                    // "Dock" for Special Tools (Admin/Driver etc)
                    if (isCurrentUser && (_isAdmin || _role != 'student'))
                      _buildQuickAccessDock(),
                  ],
                ),
              ),
            ),

            // 3. Sticky Tab Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: _brandPurple,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: _brandPurple,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  tabs: const [
                    Tab(text: "Posts"),
                    Tab(text: "Media"),
                    Tab(text: "Tagged"),
                  ],
                ),
              ),
            ),

            // 4. Content Grid
            _buildContentGrid(),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildDashboardStat(
    String label,
    String count, {
    bool isInteractive = false,
  }) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            isInteractive
                ? Border.all(color: _brandPurple.withOpacity(0.5), width: 1)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionButtons() {
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
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                "Edit Profile",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {}, // Placeholder
              color: Colors.black87,
            ),
          ),
        ],
      );
    }

    // Other User Actions
    String primaryLabel = "Connect";
    VoidCallback? primaryAction = () => _handleConnectionAction('send');
    Color primaryColor = _brandPurple;

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
      primaryColor = Colors.grey;
    } else if (_connectionStatus == ConnectionStatus.received) {
      primaryLabel = "Accept";
      primaryAction = () => _handleConnectionAction('accept');
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: primaryAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
              shadowColor: primaryColor.withOpacity(0.4),
            ),
            child: Text(
              primaryLabel,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (_connectionStatus == ConnectionStatus.connected) ...[
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _handleConnectionAction('remove'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Text(
                "Disconnect",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickAccessDock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Access",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (_role == 'driver')
                _buildDockItem(
                  "Driver",
                  Icons.local_shipping_rounded,
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DriverTrackingScreen(),
                    ),
                  ),
                ),
              if (_role == 'cafeteria_admin')
                _buildDockItem(
                  "Cafe Admin",
                  Icons.fastfood_rounded,
                  Colors.teal,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CafeteriaDashboardScreen(),
                    ),
                  ),
                ),
              if (_isAdmin)
                _buildDockItem(
                  "Admin Panel",
                  Icons.security_rounded,
                  Colors.indigo,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                  ),
                ),

              _buildDockItem(
                "Requests",
                Icons.person_add_rounded,
                Colors.blue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RequestsScreen()),
                ),
              ),
              _buildDockItem(
                "Sales",
                Icons.receipt_long_rounded,
                Colors.green,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MarketplaceSoldHistoryScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDockItem(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    switch (role) {
      case 'admin':
        color = Colors.red;
        break;
      case 'driver':
        color = Colors.orange;
        break;
      case 'teacher':
        color = Colors.green;
        break;
      default:
        color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildContentGrid() {
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
                  color: Colors.grey.shade300,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final postSnapshot = _userPosts[index];
          final data = postSnapshot.data() as Map<String, dynamic>;
          final mediaUrl =
              data['postType'] == 'video'
                  ? data['postThumbnailUrl']
                  : (data['postMediaUrl'] ?? data['postImageUrl']);

          if (mediaUrl == null) return Container(color: Colors.grey.shade200);

          return GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(postId: postSnapshot.id),
                  ),
                ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: mediaUrl,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) =>
                            Container(color: Colors.grey.shade100),
                    errorWidget:
                        (context, url, error) => const Icon(Icons.error),
                  ),
                  if (data['postType'] == 'video')
                    const Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                ],
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    'Log Out',
                    style: GoogleFonts.poppins(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _logout();
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);
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
    return Container(color: const Color(0xFFF8F9FE), child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
