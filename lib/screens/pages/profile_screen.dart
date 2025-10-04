import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:shimmer/shimmer.dart';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../admin_panel_screen.dart';
import '../connections_screen.dart';
import '../edit_profile_screen.dart';
import '../post_detail_screen.dart';
import '../requests_screen.dart';
import '../chat_screen.dart';
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

  bool _isLoading = true;
  String _displayName = 'User';
  String _username = 'username';
  String _bio = '';
  String _department = '';
  String _role = 'user';
  String? _profilePhotoUrl;
  String? _coverPhotoUrl;
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
    if (mounted && !_isLoading) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (!mounted) return;
    setState(() => _isLoading = true);

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
          _role = data['role'] ?? 'user';
          _profilePhotoUrl = data['profilePhotoUrl'];
          _coverPhotoUrl = data['coverPhotoUrl'];
          _isAdmin = data['isAdmin'] ?? false;
          _connections = data['connections'] ?? [];
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
        setState(() => _isLoading = false);
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
    if (compressedImage == null) {
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Image compression failed.')),
      );
      return;
    }
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
          const SnackBar(content: Text('Image uploaded successfully!')),
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
    if (pickedFile != null) {
      await _uploadImage(File(pickedFile.path), 'cover');
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/auth-gate',
        (route) => false,
      );
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
    final currentUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid);
    final targetUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId);
    final batch = FirebaseFirestore.instance.batch();

    batch.update(currentUserRef, {
      'sentRequests': FieldValue.arrayUnion([targetUserId]),
    });
    batch.update(targetUserRef, {
      'receivedRequests': FieldValue.arrayUnion([_currentUser.uid]),
    });

    await batch.commit();
    _loadAllData();
  }

  Future<void> _acceptConnectionRequest() async {
    final currentUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid);
    final targetUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId);
    final batch = FirebaseFirestore.instance.batch();

    batch.update(currentUserRef, {
      'connections': FieldValue.arrayUnion([targetUserId]),
    });
    batch.update(targetUserRef, {
      'connections': FieldValue.arrayUnion([_currentUser.uid]),
    });
    batch.update(currentUserRef, {
      'receivedRequests': FieldValue.arrayRemove([targetUserId]),
    });
    batch.update(targetUserRef, {
      'sentRequests': FieldValue.arrayRemove([_currentUser.uid]),
    });

    await batch.commit();
    _loadAllData();
  }

  Future<void> _cancelConnectionRequest() async {
    final currentUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid);
    final targetUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId);
    final batch = FirebaseFirestore.instance.batch();

    batch.update(currentUserRef, {
      'sentRequests': FieldValue.arrayRemove([targetUserId]),
    });
    batch.update(targetUserRef, {
      'receivedRequests': FieldValue.arrayRemove([_currentUser.uid]),
    });

    await batch.commit();
    _loadAllData();
  }

  Future<void> _removeConnection() async {
    final currentUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid);
    final targetUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId);
    final batch = FirebaseFirestore.instance.batch();

    batch.update(currentUserRef, {
      'connections': FieldValue.arrayRemove([targetUserId]),
    });
    batch.update(targetUserRef, {
      'connections': FieldValue.arrayRemove([_currentUser.uid]),
    });

    await batch.commit();
    _loadAllData();
  }

  Widget _buildRoleIcon(String role) {
    IconData? icon;
    Color? color;

    switch (role) {
      case 'admin':
        icon = Icons.admin_panel_settings;
        color = Colors.yellow;
        break;
      case 'driver':
        icon = Icons.local_shipping;
        color = Colors.cyan;
        break;
      case 'teacher':
        icon = Icons.school;
        color = Colors.green;
        break;
      case 'cafeteria_admin':
        icon = Icons.restaurant_menu;
        color = Colors.orange;
        break;
    }

    if (icon != null) {
      return Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Icon(icon, color: color, size: 24),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ProfileScreenPlaceholder();
    }

    final Color cardBackgroundColor = Colors.grey.shade900;
    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: Colors.yellow,
      backgroundColor: cardBackgroundColor,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            expandedHeight: 240,
            pinned: true,
            leading:
                isCurrentUser
                    ? null
                    : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withAlpha(128),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
            actions:
                isCurrentUser
                    ? [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withAlpha(128),
                          child: IconButton(
                            icon: const Icon(
                              Icons.group_add_outlined,
                              color: Colors.white,
                            ),
                            onPressed:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const RequestsScreen(),
                                  ),
                                ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 8,
                          bottom: 8,
                          right: 8,
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withAlpha(128),
                          child: IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            onPressed: _logout,
                          ),
                        ),
                      ),
                    ]
                    : null,
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: _pickCoverImage,
                child: _buildHeaderImage(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildProfileHeaderAndInfo(cardBackgroundColor),
          ),
          _buildPhotoGallery(),
        ],
      ),
    );
  }

  Widget _buildProfileHeaderAndInfo(Color cardColor) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.only(
              top: 70,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(30),
            ),
            child: _buildProfileInfo(),
          ),
        ),
        Positioned(
          top: 0,
          child: GestureDetector(
            onTap: _pickProfileImage,
            child: _buildProfilePicture(),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _viewConnections,
              child: _buildStatsColumn(
                _connections.length.toString(),
                "Connections",
                Colors.white,
                Colors.white70,
              ),
            ),
            const SizedBox(width: 40),
            _buildStatsColumn(
              _userPosts.length.toString(),
              "Posts",
              Colors.white,
              Colors.white70,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                _displayName,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildRoleIcon(_role),
          ],
        ),
        Text(
          '@$_username',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 16,
            decoration: TextDecoration.none,
          ),
        ),
        if (_department.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.school_outlined,
                  size: 16,
                  color: Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  _department,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Text(
          _bio.isEmpty ? 'This user has no bio yet.' : _bio,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: _bio.isEmpty ? Colors.grey : Colors.white70,
            fontSize: 14,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 20),
        _buildActionButtons(),
        const SizedBox(height: 24),
        _buildTabs(Colors.yellow, Colors.white, Colors.white70),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (isCurrentUser) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // DRIVER BUTTON
          if (_role == 'driver') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DriverTrackingScreen(),
                      ),
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.drive_eta_outlined),
                label: Text(
                  'Driver Mode',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // CAFETERIA ADMIN BUTTON
          if (_role == 'cafeteria_admin') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CafeteriaDashboardScreen(),
                      ),
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.restaurant_menu_outlined),
                label: Text(
                  'Manage Cafeteria',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // MAIN ADMIN BUTTON
          if (_isAdmin) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminPanelScreen(),
                      ),
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: Text(
                  'Admin Panel',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // EDIT PROFILE BUTTON (Always shows if it's the current user)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
                _loadAllData();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.yellow,
                side: const BorderSide(color: Colors.yellow),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Edit Profile',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }
    // Logic for viewing other users' profiles
    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ChatScreen(
                              receiverId: targetUserId,
                              receiverName: _displayName,
                              receiverImageUrl: _profilePhotoUrl ?? '',
                            ),
                      ),
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                ),
                icon: const Icon(Icons.message_outlined),
                label: const Text('Message'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _removeConnection,
              child: const Text('Unconnect'),
            ),
          ],
        );
      case ConnectionStatus.sent:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _cancelConnectionRequest,
            child: const Text('Cancel Request'),
          ),
        );
      case ConnectionStatus.received:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _acceptConnectionRequest,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept Request'),
          ),
        );
      case ConnectionStatus.none:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _sendConnectionRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: Text(
              'Connect',
              style: GoogleFonts.poppins(decoration: TextDecoration.none),
            ),
          ),
        );
    }
  }

  Widget _buildHeaderImage() {
    ImageProvider imageProvider;
    if (_coverPhotoUrl != null && _coverPhotoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_coverPhotoUrl!);
    } else {
      imageProvider = const NetworkImage(
        'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?auto=format&fit=crop&w=1470',
      );
    }
    return Container(
      height: 240,
      decoration: BoxDecoration(
        image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildProfilePicture() {
    final cardColor = Colors.grey.shade900;
    ImageProvider imageProvider;
    if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_profilePhotoUrl!);
    } else {
      imageProvider = const NetworkImage('https://i.pravatar.cc/150?img=31');
    }
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: cardColor, width: 5),
      ),
      child: CircleAvatar(radius: 45, backgroundImage: imageProvider),
    );
  }

  Widget _buildStatsColumn(
    String value,
    String label,
    Color textColor,
    Color secondaryColor,
  ) => Column(
    children: [
      Text(
        value,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: textColor,
          decoration: TextDecoration.none,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: GoogleFonts.poppins(
          color: secondaryColor,
          fontSize: 14,
          decoration: TextDecoration.none,
        ),
      ),
    ],
  );

  Widget _buildTabs(
    Color activeColor,
    Color activeTextColor,
    Color inactiveTextColor,
  ) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      _buildTabItem('All', ProfileTab.all, activeColor, inactiveTextColor),
      _buildTabItem(
        'Photos',
        ProfileTab.photos,
        activeColor,
        inactiveTextColor,
      ),
      _buildTabItem(
        'Videos',
        ProfileTab.videos,
        activeColor,
        inactiveTextColor,
      ),
    ],
  );

  Widget _buildTabItem(
    String title,
    ProfileTab tab,
    Color activeColor,
    Color inactiveTextColor,
  ) {
    final bool isActive = _selectedTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tab),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
              color: isActive ? activeColor : inactiveTextColor,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          if (isActive) Container(width: 25, height: 3, color: activeColor),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery() {
    final cardColor = Colors.grey.shade900;
    final List<DocumentSnapshot> filteredPosts;
    switch (_selectedTab) {
      case ProfileTab.photos:
        filteredPosts =
            _userPosts.where((post) {
              final data = post.data() as Map<String, dynamic>;
              return (data['postType'] == 'image') ||
                  (data['postType'] == null && data['postImageUrl'] != null);
            }).toList();
        break;
      case ProfileTab.videos:
        filteredPosts =
            _userPosts.where((post) {
              final data = post.data() as Map<String, dynamic>;
              return data['postType'] == 'video';
            }).toList();
        break;
      case ProfileTab.all:
        filteredPosts = _userPosts;
        break;
    }
    if (filteredPosts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Center(
            child: Text(
              'This user has no ${_selectedTab.name} yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 1.0,
        ),
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          final postSnapshot = filteredPosts[index];
          final postData = postSnapshot.data() as Map<String, dynamic>;
          final postType = postData['postType'];
          final String? mediaUrl =
              postType == 'video'
                  ? postData['postThumbnailUrl']
                  : postData['postMediaUrl'] ?? postData['postImageUrl'];
          if (mediaUrl == null || mediaUrl.isEmpty) {
            return Container(
              color: cardColor,
              child: const Icon(
                Icons.no_photography_outlined,
                color: Colors.white30,
              ),
            );
          }
          return GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PostDetailScreen(postId: postSnapshot.id),
                  ),
                ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    mediaUrl,
                    fit: BoxFit.cover,
                    loadingBuilder:
                        (context, child, progress) =>
                            progress == null
                                ? child
                                : Container(
                                  color: Colors.grey.shade800,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.yellow,
                                    ),
                                  ),
                                ),
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          color: Colors.grey.shade800,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.white54,
                          ),
                        ),
                  ),
                  if (postType == 'video')
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white70,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ),
          );
        }, childCount: filteredPosts.length),
      ),
    );
  }
}

class ProfileScreenPlaceholder extends StatelessWidget {
  const ProfileScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final cardBackgroundColor = Colors.grey.shade900;
    final shimmerBaseColor = Colors.grey.shade800;
    final shimmerHighlightColor = Colors.grey.shade700;

    return Shimmer.fromColors(
      baseColor: shimmerBaseColor,
      highlightColor: shimmerHighlightColor,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            expandedHeight: 240,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(color: shimmerBaseColor),
            ),
          ),
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 60),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    padding: const EdgeInsets.only(
                      top: 70,
                      left: 20,
                      right: 20,
                      bottom: 20,
                    ),
                    decoration: BoxDecoration(
                      color: cardBackgroundColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPlaceholderContainer(width: 50, height: 30),
                            const SizedBox(width: 40),
                            _buildPlaceholderContainer(width: 50, height: 30),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildPlaceholderContainer(width: 150, height: 22),
                        const SizedBox(height: 4),
                        _buildPlaceholderContainer(width: 100, height: 16),
                        const SizedBox(height: 12),
                        _buildPlaceholderContainer(
                          width: double.infinity,
                          height: 14,
                        ),
                        const SizedBox(height: 4),
                        _buildPlaceholderContainer(width: 200, height: 14),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cardBackgroundColor, width: 5),
                    ),
                    child: const CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
                childCount: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderContainer({
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
