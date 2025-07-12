import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImageFile;
  File? _coverImageFile;
  String _bio = '';

  Future<void> _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImageFile = File(pickedFile.path);
      });
      // TODO: Here you would upload _profileImageFile to a server like Firebase Storage
    }
  }

  Future<void> _pickCoverImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _coverImageFile = File(pickedFile.path);
      });
      // TODO: Here you would upload _coverImageFile to a server like Firebase Storage
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // FIX: Guard with mounted check and enclose in a block
      if (!mounted) {
        return;
      }
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Your Name';
    final username = user?.email?.split('@').first ?? 'username';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHeaderAndProfile(displayName, username),
              _buildPhotoGallery(),
            ],
          ),
          _buildTopActionButtons(),
        ],
      ),
    );
  }

  Widget _buildTopActionButtons() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withAlpha(200),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withAlpha(200),
                  child: IconButton(
                    icon: const Icon(Icons.mail_outline, color: Colors.black87),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.white.withAlpha(200),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.black87),
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

  Widget _buildHeaderAndProfile(String displayName, String username) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 150),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.only(top: 70, left: 20, right: 20, bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF2FA),
              borderRadius: BorderRadius.circular(30),
            ),
            child: _buildProfileInfo(displayName, username),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickCoverImage,
            child: _buildHeaderImage(),
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

  Widget _buildProfileInfo(String displayName, String username) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatsColumn("0", "Followers"),
            const SizedBox(width: 80),
            _buildStatsColumn("0", "Following"),
          ],
        ),
        const SizedBox(height: 10),
        Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        Text('@$username', style: const TextStyle(color: Colors.grey, fontSize: 16)),
        const SizedBox(height: 12),
        Text(
          _bio.isEmpty ? 'No bio yet. Tap "Edit Profile" to add one.' : _bio,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _bio.isEmpty ? Colors.grey : Colors.black54,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen(currentBio: _bio)),
              );
              if (result != null && result is String) {
                setState(() {
                  _bio = result;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C85E4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 24),
        _buildTabs(),
      ],
    );
  }

  Widget _buildHeaderImage() {
    ImageProvider imageProvider;
    if (_coverImageFile != null) {
      imageProvider = FileImage(_coverImageFile!);
    } else {
      imageProvider = const NetworkImage('https://images.unsplash.com/photo-1579546929518-9e396f3cc809?auto=format&fit=crop&w=1470');
    }
    return Container(
      height: 240,
      decoration: BoxDecoration(
        image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildProfilePicture() {
    ImageProvider imageProvider;
    if (_profileImageFile != null) {
      imageProvider = FileImage(_profileImageFile!);
    } else {
      imageProvider = const NetworkImage('https://i.pravatar.cc/150?img=31');
    }
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFEBF2FA), width: 5),
      ),
      child: CircleAvatar(radius: 45, backgroundImage: imageProvider),
    );
  }

  // --- FIX: Full implementations for all helper methods ---
  Widget _buildStatsColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
      ],
    );
  }

  Widget _buildTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          children: [
            const Text('All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Container(width: 25, height: 3, color: Colors.black87),
          ],
        ),
        Text('Photos', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        Text('Videos', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
      ],
    );
  }

  Widget _buildPhotoGallery() {
    final List<String> imageUrls = [
      'https://images.unsplash.com/photo-1573443742690-35347e30559a?auto=format&fit=crop&w=400',
      'https://images.unsplash.com/photo-1562932832-9b2f67274488?auto=format&fit=crop&w=400',
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=400',
      'https://images.unsplash.com/photo-1534484094124-736318553da7?auto=format&fit=crop&w=400',
      'https://images.unsplash.com/photo-1541701494587-cb58502866ab?auto=format&fit=crop&w=400',
      'https://images.unsplash.com/photo-1508189860359-777d94268b37?auto=format&fit=crop&w=400',
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25.0)),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: AspectRatio(aspectRatio: 2 / 3, child: _buildGalleryImage(imageUrls[0]))),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      AspectRatio(aspectRatio: 3 / 2, child: _buildGalleryImage(imageUrls[1])),
                      const SizedBox(height: 8),
                      AspectRatio(aspectRatio: 3 / 2, child: _buildGalleryImage(imageUrls[2])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: AspectRatio(aspectRatio: 1, child: _buildGalleryImage(imageUrls[3]))),
                const SizedBox(width: 8),
                Expanded(child: AspectRatio(aspectRatio: 1, child: _buildGalleryImage(imageUrls[4]))),
                const SizedBox(width: 8),
                Expanded(child: AspectRatio(aspectRatio: 1, child: _buildGalleryImage(imageUrls[5]))),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15.0),
      child: Image.network(url, fit: BoxFit.cover),
    );
  }
}