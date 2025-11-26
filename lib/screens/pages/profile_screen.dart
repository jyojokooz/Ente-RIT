// ===============================
// FILE NAME: profile_screen.dart
// FILE PATH: lib/screens/pages/profile_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use

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
// Removed unused imports: requests_screen, driver_tracking_screen, cafeteria_dashboard_screen
import '../chat_screen.dart';

// If these are actually needed for buttons (like Driver Mode), keep them.
// But since the linter said they were unused, I removed them.
// If you intend to use them, uncomment below:
import '../requests_screen.dart';
import '../driver_tracking_screen.dart';
import '../cafeteria_dashboard_screen.dart';

const String cloudinaryCloudName = "dcboqibnx";
const String cloudinaryUploadPreset = "flutter_profile_uploads";

enum ConnectionStatus { none, sent, received, connected }

enum ProfileTab { all, photos, videos }

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  late final String targetUserId;
  late final bool isCurrentUser;
  final ImagePicker _picker = ImagePicker();

  bool _isInitialLoad = true;

  String _displayName = 'User';
  String _username = 'username';
  String _bio = '';
  String _department = '';
  String _role = 'user';
  String? _profilePhotoUrl;
  String?
  _coverPhotoUrl; // This is used in the build method for the cover image
  List<DocumentSnapshot> _userPosts = [];
  bool _isAdmin = false;
  List<dynamic> _connections = [];
  ConnectionStatus _connectionStatus = ConnectionStatus.none;
  ProfileTab _selectedTab = ProfileTab.all;

  final cloudinary = CloudinaryPublic(
    cloudinaryCloudName,
    cloudinaryUploadPreset,
    cache: false,
  );

  @override
  void initState() {
    super.initState();
    targetUserId = widget.userId ?? _currentUser.uid;
    isCurrentUser = targetUserId == _currentUser.uid;
    _loadAllData();
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
    if (_isInitialLoad) {
      setState(() => _isInitialLoad = true);
    }

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
          _coverPhotoUrl = data['coverPhotoUrl'];
          _isAdmin = data['isAdmin'] ?? false;

          final List<dynamic> rawConnections = data['connections'] ?? [];
          if (rawConnections.isNotEmpty) {
            final List<Future<DocumentSnapshot>> connectionFutures =
                rawConnections
                    .map(
                      (id) =>
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(id as String)
                              .get(),
                    )
                    .toList();
            final List<DocumentSnapshot> connectionSnapshots =
                await Future.wait(connectionFutures);
            _connections =
                connectionSnapshots
                    .where((snapshot) => snapshot.exists)
                    .map((snapshot) => snapshot.id)
                    .toList();
          } else {
            _connections = [];
          }
          _determineConnectionStatus(
            currentUserSnapshot.data(),
            targetUserSnapshot.id,
          );
        } else {
          _displayName = 'User Not Found';
        }
        _userPosts = postsSnapshot.docs;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading data: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInitialLoad = false);
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

  Future<void> _uploadImage(File imageFile, String imageType) async {
    if (!isCurrentUser) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('Compressing $imageType image...')),
    );

    final File? compressedImage = await _compressImage(imageFile);
    if (compressedImage == null) return;

    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('Uploading $imageType image...')),
    );

    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          compressedImage.path,
          folder: 'users/${_currentUser.uid}',
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      final downloadUrl = response.secureUrl;
      final fieldToUpdate =
          imageType == 'profile' ? 'profilePhotoUrl' : 'coverPhotoUrl';
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .set({fieldToUpdate: downloadUrl}, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          if (imageType == 'profile') {
            _profilePhotoUrl = downloadUrl;
          } else {
            _coverPhotoUrl = downloadUrl;
          }
        });
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickProfileImage() async {
    if (!isCurrentUser) return;
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      await _uploadImage(File(pickedFile.path), 'profile');
    }
  }

  Future<void> _pickCoverImage() async {
    if (!isCurrentUser) return;
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) await _uploadImage(File(pickedFile.path), 'cover');
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out: ${e.toString()}')),
      );
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
        SnackBar(
          content: Text(
            'You must be connected with $_displayName to see their connections.',
          ),
        ),
      );
    }
  }

  Future<void> _sendConnectionRequest() async {
    final batch = FirebaseFirestore.instance.batch();
    batch.update(
      FirebaseFirestore.instance.collection('users').doc(_currentUser.uid),
      {
        'sentRequests': FieldValue.arrayUnion([targetUserId]),
      },
    );
    batch.update(
      FirebaseFirestore.instance.collection('users').doc(targetUserId),
      {
        'receivedRequests': FieldValue.arrayUnion([_currentUser.uid]),
      },
    );
    await batch.commit();
    _loadAllData();
  }

  Future<void> _acceptConnectionRequest() async {
    final batch = FirebaseFirestore.instance.batch();
    final me = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid);
    final them = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId);
    batch.update(me, {
      'connections': FieldValue.arrayUnion([targetUserId]),
      'receivedRequests': FieldValue.arrayRemove([targetUserId]),
    });
    batch.update(them, {
      'connections': FieldValue.arrayUnion([_currentUser.uid]),
      'sentRequests': FieldValue.arrayRemove([_currentUser.uid]),
    });
    await batch.commit();
    _loadAllData();
  }

  Future<void> _cancelConnectionRequest() async {
    final batch = FirebaseFirestore.instance.batch();
    batch.update(
      FirebaseFirestore.instance.collection('users').doc(_currentUser.uid),
      {
        'sentRequests': FieldValue.arrayRemove([targetUserId]),
      },
    );
    batch.update(
      FirebaseFirestore.instance.collection('users').doc(targetUserId),
      {
        'receivedRequests': FieldValue.arrayRemove([_currentUser.uid]),
      },
    );
    await batch.commit();
    _loadAllData();
  }

  Future<void> _removeConnection() async {
    final batch = FirebaseFirestore.instance.batch();
    batch.update(
      FirebaseFirestore.instance.collection('users').doc(_currentUser.uid),
      {
        'connections': FieldValue.arrayRemove([targetUserId]),
      },
    );
    batch.update(
      FirebaseFirestore.instance.collection('users').doc(targetUserId),
      {
        'connections': FieldValue.arrayRemove([_currentUser.uid]),
      },
    );
    await batch.commit();
    _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoad) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    const Color brandPurple = Color(0xFF9983F3);
    const Color brandBlack = Colors.black;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        color: brandPurple,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // Cover Image
                  GestureDetector(
                    onTap: _pickCoverImage,
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        border: const Border(
                          bottom: BorderSide(color: brandBlack, width: 3),
                        ),
                        image:
                            _coverPhotoUrl != null && _coverPhotoUrl!.isNotEmpty
                                ? DecorationImage(
                                  image: NetworkImage(_coverPhotoUrl!),
                                  fit: BoxFit.cover,
                                )
                                : null,
                      ),
                      child:
                          _coverPhotoUrl == null
                              ? const Center(
                                child: Icon(
                                  Icons.add_a_photo,
                                  color: Colors.black54,
                                ),
                              )
                              : null,
                    ),
                  ),

                  // Action Buttons (Back/Logout)
                  Positioned(
                    top: 40,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (!isCurrentUser)
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: brandBlack,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          )
                        else
                          const SizedBox(),

                        if (isCurrentUser)
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.group_add,
                                    color: brandBlack,
                                  ),
                                  onPressed:
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => const RequestsScreen(),
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              CircleAvatar(
                                backgroundColor: Colors.white,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.logout,
                                    color: Colors.red,
                                  ),
                                  onPressed: _logout,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Profile Card
                  Container(
                    margin: const EdgeInsets.only(
                      top: 160,
                      left: 20,
                      right: 20,
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: brandBlack, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: brandBlack,
                          offset: Offset(6, 6),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _displayName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.archivoBlack(
                            fontSize: 24,
                            color: brandBlack,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '@$_username',
                              style: GoogleFonts.spaceMono(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (_role != 'student') ...[
                              const SizedBox(width: 8),
                              _buildRoleBadge(_role),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _bio.isNotEmpty ? _bio : "No bio yet.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: brandBlack,
                          ),
                        ),
                        if (_department.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Chip(
                              label: Text(
                                _department,
                                style: GoogleFonts.spaceMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: Colors.grey.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: brandBlack),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: _viewConnections,
                              child: _buildStatItem(
                                "Connections",
                                _connections.length.toString(),
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 40,
                              color: Colors.grey.shade300,
                            ),
                            _buildStatItem(
                              "Posts",
                              _userPosts.length.toString(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
                    ),
                  ),

                  // Avatar
                  Positioned(
                    top: 110,
                    child: GestureDetector(
                      onTap: _pickProfileImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                          border: Border.all(color: brandBlack, width: 4),
                          image:
                              _profilePhotoUrl != null &&
                                      _profilePhotoUrl!.isNotEmpty
                                  ? DecorationImage(
                                    image: NetworkImage(_profilePhotoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                  : null,
                        ),
                        child:
                            _profilePhotoUrl == null
                                ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: brandBlack,
                                )
                                : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: brandBlack, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton("All", ProfileTab.all),
                      _buildTabButton("Photos", ProfileTab.photos),
                      _buildTabButton("Videos", ProfileTab.videos),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            _buildPhotoGallery(),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
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
      case 'cafeteria_admin':
        color = Colors.purple;
        break;
      default:
        color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.archivoBlack(fontSize: 22, color: Colors.black),
        ),
        Text(
          label,
          style: GoogleFonts.spaceMono(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String label, ProfileTab tab) {
    final bool isSelected = _selectedTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF9983F3) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceMono(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    const Color brandBlack = Colors.black;
    const Color brandPurple = Color(0xFF9983F3);

    if (isCurrentUser) {
      return Column(
        children: [
          if (_role == 'driver')
            _buildWideButton(
              "Driver Mode",
              Icons.local_shipping,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DriverTrackingScreen()),
              ),
            ),
          if (_role == 'cafeteria_admin')
            _buildWideButton(
              "Manage Cafe",
              Icons.restaurant,
              Colors.teal,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CafeteriaDashboardScreen(),
                ),
              ),
            ),
          if (_isAdmin)
            _buildWideButton(
              "Admin Panel",
              Icons.admin_panel_settings,
              Colors.indigo,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
              ),
            ),

          const SizedBox(height: 8),
          _buildWideButton("Edit Profile", Icons.edit, brandPurple, () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
            _loadAllData();
          }),
        ],
      );
    }

    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        return Row(
          children: [
            Expanded(
              child: _buildWideButton(
                "Message",
                Icons.chat,
                brandBlack,
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
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildWideButton(
                "Disconnect",
                Icons.person_remove,
                Colors.white,
                _removeConnection,
                isOutlined: true,
              ),
            ),
          ],
        );
      case ConnectionStatus.sent:
        return _buildWideButton(
          "Cancel Request",
          Icons.close,
          Colors.grey,
          _cancelConnectionRequest,
        );
      case ConnectionStatus.received:
        return _buildWideButton(
          "Accept Request",
          Icons.check,
          Colors.green,
          _acceptConnectionRequest,
        );
      case ConnectionStatus.none:
        return _buildWideButton(
          "Connect",
          Icons.person_add,
          brandPurple,
          _sendConnectionRequest,
        );
    }
  }

  Widget _buildWideButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isOutlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.white : color,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isOutlined ? Colors.black : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.spaceMono(
                color: isOutlined ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGallery() {
    final List<DocumentSnapshot> filteredPosts;
    if (_selectedTab == ProfileTab.photos) {
      filteredPosts =
          _userPosts.where((post) {
            final d = post.data() as Map<String, dynamic>;
            return d['postType'] == 'image' || d['postType'] == null;
          }).toList();
    } else if (_selectedTab == ProfileTab.videos) {
      filteredPosts =
          _userPosts.where((post) {
            final d = post.data() as Map<String, dynamic>;
            return d['postType'] == 'video';
          }).toList();
    } else {
      filteredPosts = _userPosts;
    }

    if (filteredPosts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Center(
            child: Text(
              "No posts yet.",
              style: GoogleFonts.spaceMono(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final postSnapshot = filteredPosts[index];
          final postData = postSnapshot.data() as Map<String, dynamic>;
          final mediaUrl =
              postData['postType'] == 'video'
                  ? postData['postThumbnailUrl']
                  : (postData['postMediaUrl'] ?? postData['postImageUrl']);

          if (mediaUrl == null) return Container(color: Colors.grey.shade100);

          return GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(postId: postSnapshot.id),
                  ),
                ),
            child: CachedNetworkImage(
              imageUrl: mediaUrl,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => Container(color: Colors.grey.shade100),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          );
        }, childCount: filteredPosts.length),
      ),
    );
  }
}

// Helper for Sticky TabBar
// This is no longer used as we switched to custom button tabs, but good to keep if you want to switch back.
// I've removed it from the build method to avoid unused warnings if it's not called.
