import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'admin_panel_screen.dart';
import 'connections_screen.dart'; // <-- 1. ADD THIS IMPORT
import 'edit_profile_screen.dart';
import 'post_detail_screen.dart';
import 'requests_screen.dart';

const String cloudinaryCloudName = "dcboqibnx";
const String cloudinaryUploadPreset = "flutter_profile_uploads";

enum ConnectionStatus { none, sent, received, connected }

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
  File? _profileImageFile;
  File? _coverImageFile;

  bool _isLoading = true;
  String _displayName = 'User';
  String _username = 'username';
  String _bio = '';
  String? _profilePhotoUrl;
  String? _coverPhotoUrl;
  List<DocumentSnapshot> _userPosts = [];
  bool _isAdmin = false;
  List<dynamic> _connections = []; // <-- Store the list of connection IDs
  ConnectionStatus _connectionStatus = ConnectionStatus.none;

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

  Future<void> _loadAllData() async {
    // ... This method is mostly the same
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
          _profilePhotoUrl = data['profilePhotoUrl'];
          _coverPhotoUrl = data['coverPhotoUrl'];
          _isAdmin = data['isAdmin'] ?? false;
          _connections =
              data['connections'] ?? []; // <-- 2. POPULATE THE CONNECTIONS LIST
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // All other helper methods (_determineConnectionStatus, _sendConnectionRequest, etc.) are unchanged
  // ...

  // --- 3. NEW NAVIGATION METHOD FOR VIEWING CONNECTIONS ---
  void _viewConnections() {
    // A user can always see their own connections.
    // Another user can only see connections if they are connected.
    if (isCurrentUser || _connectionStatus == ConnectionStatus.connected) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ConnectionsScreen(
                title: '$_displayName\'s Connections',
                userIds: _connections,
              ),
        ),
      );
    } else {
      // Optionally, show a message if they try to view connections but aren't connected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You must be connected with $_displayName to see their connections.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... The main build method is unchanged
    return Scaffold(
      backgroundColor: Colors.black,
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.yellow),
              )
              : Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _loadAllData,
                    color: Colors.yellow,
                    backgroundColor: Colors.grey.shade900,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeaderAndProfile()),
                        _buildPhotoGallery(),
                      ],
                    ),
                  ),
                  _buildTopActionButtons(),
                ],
              ),
    );
  }

  // --- 4. UPDATE _buildProfileInfo TO MAKE THE STATS COLUMN TAPPABLE ---
  Widget _buildProfileInfo() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Wrap the Connections column in a GestureDetector
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
        // ... the rest of the method is unchanged
        const SizedBox(height: 10),
        Text(
          _displayName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        Text(
          '@$_username',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Text(
          _bio.isEmpty ? 'This user has no bio yet.' : _bio,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: _bio.isEmpty ? Colors.grey : Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        _buildActionButtons(),
        const SizedBox(height: 24),
        _buildTabs(Colors.yellow, Colors.white, Colors.white70),
      ],
    );
  }

  // All other methods from here on are unchanged...
  // ...
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

  Future<void> _sendConnectionRequest() async {
    final currentUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid);
    final targetUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId);
    await currentUserRef.update({
      'sentRequests': FieldValue.arrayUnion([targetUserId]),
    });
    await targetUserRef.update({
      'receivedRequests': FieldValue.arrayUnion([_currentUser.uid]),
    });
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

  Future<void> _uploadImage(File imageFile, String imageType) async {
    if (!isCurrentUser) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Uploading $imageType image...')));
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
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
      setState(() {
        if (imageType == 'profile') {
          _profilePhotoUrl = downloadUrl;
          _profileImageFile = null;
        } else {
          _coverPhotoUrl = downloadUrl;
          _coverImageFile = null;
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: ${e.toString()}')));
    }
  }

  Future<void> _pickProfileImage() async {
    if (!isCurrentUser) return;
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      setState(() => _profileImageFile = imageFile);
      await _uploadImage(imageFile, 'profile');
    }
  }

  Future<void> _pickCoverImage() async {
    if (!isCurrentUser) return;
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      setState(() => _coverImageFile = imageFile);
      await _uploadImage(imageFile, 'cover');
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out: ${e.toString()}')),
      );
    }
  }

  Widget _buildTopActionButtons() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: Colors.black.withAlpha(128),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (isCurrentUser)
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black.withAlpha(128),
                    child: IconButton(
                      icon: const Icon(
                        Icons.group_add_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RequestsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.black.withAlpha(128),
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: _logout,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAndProfile() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        GestureDetector(onTap: _pickCoverImage, child: _buildHeaderImage()),
        Container(
          margin: const EdgeInsets.only(top: 150),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(30),
            ),
            child: _buildProfileInfo(),
          ),
        ),
        Positioned(
          top: 100,
          child: GestureDetector(
            onTap: _pickProfileImage,
            child: _buildProfilePicture(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (isCurrentUser) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('Admin Panel'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
                _loadAllData();
              },
              child: const Text('Edit Profile'),
            ),
          ),
        ],
      );
    }
    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade700,
            ),
            icon: const Icon(Icons.message_outlined),
            label: const Text('Message'),
            onPressed: () {},
          ),
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
            label: const Text('Connect'),
          ),
        );
    }
  }

  Widget _buildHeaderImage() {
    ImageProvider imageProvider;
    if (isCurrentUser && _coverImageFile != null) {
      imageProvider = FileImage(_coverImageFile!);
    } else if (_coverPhotoUrl != null && _coverPhotoUrl!.isNotEmpty) {
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
    if (isCurrentUser && _profileImageFile != null) {
      imageProvider = FileImage(_profileImageFile!);
    } else if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty) {
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
  ) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(color: secondaryColor, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTabs(
    Color activeColor,
    Color activeTextColor,
    Color inactiveTextColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          children: [
            Text(
              'All',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: activeColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(width: 25, height: 3, color: activeColor),
          ],
        ),
        Text(
          'Photos',
          style: GoogleFonts.poppins(color: inactiveTextColor, fontSize: 16),
        ),
        Text(
          'Videos',
          style: GoogleFonts.poppins(color: inactiveTextColor, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildPhotoGallery() {
    final cardColor = Colors.grey.shade900;
    if (_userPosts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Center(
            child: Text(
              'This user has no posts yet.',
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
          final postSnapshot = _userPosts[index];
          final postData = postSnapshot.data() as Map<String, dynamic>;
          final imageUrl = postData['postImageUrl'] as String?;
          if (imageUrl == null || imageUrl.isEmpty) {
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
                        (context) =>
                            PostDetailScreen(postSnapshot: postSnapshot),
                  ),
                ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
              child: Image.network(
                imageUrl,
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
            ),
          );
        }, childCount: _userPosts.length),
      ),
    );
  }
}
