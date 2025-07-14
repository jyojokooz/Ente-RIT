import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'admin_panel_screen.dart';
import 'edit_profile_screen.dart';

const String cloudinaryCloudName = "dcboqibnx";
const String cloudinaryUploadPreset = "flutter_profile_uploads";

class ProfileScreen extends StatefulWidget {
  // --- ADD THIS ---
  // This will allow us to pass a specific user ID to view their profile.
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImageFile;
  File? _coverImageFile;

  // --- STATE VARIABLES ---
  late final String targetUserId; // The ID of the profile we are viewing
  late final bool isCurrentUser; // Is this the logged-in user's own profile?

  String _displayName = 'User';
  String _username = 'username';
  String _bio = '';
  String? _profilePhotoUrl;
  String? _coverPhotoUrl;
  bool _isLoading = true;
  List<DocumentSnapshot> _userPosts = [];
  bool _isAdmin = false;

  final cloudinary = CloudinaryPublic(
    cloudinaryCloudName,
    cloudinaryUploadPreset,
    cache: false,
  );

  @override
  void initState() {
    super.initState();
    // --- UPDATED LOGIC ---
    // If a userId is passed, we view that user. Otherwise, we view the logged-in user.
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    targetUserId = widget.userId ?? currentUserId;
    isCurrentUser = targetUserId == currentUserId;

    _loadUserDataAndPosts();
  }

  Future<void> _loadUserDataAndPosts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Use targetUserId to fetch data for the correct profile
      final userDocFuture =
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

      final results = await Future.wait([userDocFuture, postsQueryFuture]);
      final docSnapshot = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final postsSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;

      if (mounted) {
        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          _displayName = data['displayName'] ?? 'User';
          _username = data['username'] ?? 'username';
          _bio = data['bio'] ?? '';
          _profilePhotoUrl = data['profilePhotoUrl'];
          _coverPhotoUrl = data['coverPhotoUrl'];
          _isAdmin = data['isAdmin'] ?? false;
        } else {
          // Handle case where profile doesn't exist
          _displayName = 'User Not Found';
        }
        _userPosts = postsSnapshot.docs;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // All other helper methods (_uploadImage, _pickImage, _logout, etc.) remain the same
  // ...
  Future<void> _uploadImage(File imageFile, String imageType) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !isCurrentUser) return; // Can only upload for self
    // ... rest of upload logic ...
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Uploading $imageType image...')));
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'users/${user.uid}',
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      final downloadUrl = response.secureUrl;
      final fieldToUpdate =
          imageType == 'profile' ? 'profilePhotoUrl' : 'coverPhotoUrl';
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        fieldToUpdate: downloadUrl,
      }, SetOptions(merge: true));
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
    } on CloudinaryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    }
  }

  Future<void> _pickProfileImage() async {
    if (!isCurrentUser) return; // Can only edit own profile
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      setState(() => _profileImageFile = imageFile);
      await _uploadImage(imageFile, 'profile');
    }
  }

  Future<void> _pickCoverImage() async {
    if (!isCurrentUser) return; // Can only edit own profile
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

  @override
  Widget build(BuildContext context) {
    // ... build method is the same
    const Color screenBackgroundColor = Colors.black;
    const Color primaryAccentColor = Colors.yellow;
    final Color cardBackgroundColor = Colors.grey.shade900;
    return Scaffold(
      backgroundColor: screenBackgroundColor,
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: primaryAccentColor),
              )
              : Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _loadUserDataAndPosts,
                    color: primaryAccentColor,
                    backgroundColor: cardBackgroundColor,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildHeaderAndProfile(cardBackgroundColor),
                        ),
                        _buildPhotoGallery(cardBackgroundColor),
                      ],
                    ),
                  ),
                  _buildTopActionButtons(Colors.black, Colors.white),
                ],
              ),
    );
  }

  Widget _buildTopActionButtons(Color bgColor, Color iconColor) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: bgColor.withAlpha(128),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: iconColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // Only show logout and mail if it's the current user's profile
            if (isCurrentUser)
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: bgColor.withAlpha(128),
                    child: IconButton(
                      icon: Icon(Icons.mail_outline, color: iconColor),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: bgColor.withAlpha(128),
                    child: IconButton(
                      icon: Icon(Icons.logout, color: iconColor),
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

  // ... Other _build methods
  Widget _buildHeaderAndProfile(Color cardColor) {
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
              color: cardColor,
              borderRadius: BorderRadius.circular(30),
            ),
            child: _buildProfileInfo(),
          ),
        ),
        Positioned(
          top: 100,
          child: GestureDetector(
            onTap: _pickProfileImage,
            child: _buildProfilePicture(cardColor),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    const Color primaryAccentColor = Colors.yellow;
    const Color primaryTextColor = Colors.white;
    const Color secondaryTextColor = Colors.white70;
    const Color buttonTextColor = Colors.black;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatsColumn(
              "0",
              "Followers",
              primaryTextColor,
              secondaryTextColor,
            ),
            _buildStatsColumn(
              _userPosts.length.toString(),
              "Posts",
              primaryTextColor,
              secondaryTextColor,
            ),
            _buildStatsColumn(
              "0",
              "Following",
              primaryTextColor,
              secondaryTextColor,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _displayName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: primaryTextColor,
          ),
        ),
        Text(
          '@$_username',
          style: GoogleFonts.poppins(color: secondaryTextColor, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Text(
          _bio.isEmpty ? 'This user has no bio yet.' : _bio,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: _bio.isEmpty ? Colors.grey : secondaryTextColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),

        // --- SHOW BUTTONS ONLY IF IT'S THE CURRENT USER'S PROFILE ---
        if (isCurrentUser)
          Column(
            children: [
              if (_isAdmin) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: Text(
                      'Admin Panel',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                    if (result == true) {
                      _loadUserDataAndPosts();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAccentColor,
                    foregroundColor: buttonTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
          ),

        const SizedBox(height: 24),
        _buildTabs(primaryAccentColor, primaryTextColor, secondaryTextColor),
      ],
    );
  }

  // ... rest of the build methods are the same ...
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

  Widget _buildProfilePicture(Color borderColor) {
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
        border: Border.all(color: borderColor, width: 5),
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

  Widget _buildPhotoGallery(Color cardColor) {
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
          final postData = _userPosts[index].data() as Map<String, dynamic>;
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
          return ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: Colors.grey.shade800,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.yellow,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade800,
                  child: const Icon(Icons.broken_image, color: Colors.white54),
                );
              },
            ),
          );
        }, childCount: _userPosts.length),
      ),
    );
  }
}
