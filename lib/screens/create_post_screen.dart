// ===============================
// FILE NAME: create_post_screen.dart
// FILE PATH: lib/screens/create_post_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

const String cloudinaryCloudName = "dcboqibnx";
const String cloudinaryUploadPreset = "flutter_profile_uploads";

enum PostType { image, video, none }

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final _user = FirebaseAuth.instance.currentUser!;

  // Media State
  List<File> _mediaFiles = [];
  File? _thumbnailFile;
  PostType _postType = PostType.none;

  // UI State
  bool _isUploading = false;
  String _uploadStatus = '';
  int _currentImageIndex = 0;

  // --- COMPRESSION METHODS ---
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

  Future<File?> _compressVideo(File file) async {
    setState(() => _uploadStatus = 'Compressing video...');
    final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
      file.path,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
    );
    return mediaInfo?.file;
  }

  Future<void> _generateThumbnail(String videoPath) async {
    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      imageFormat: ImageFormat.JPEG,
      quality: 75,
    );
    if (thumbnailPath != null && mounted) {
      setState(() {
        _thumbnailFile = File(thumbnailPath);
      });
    }
  }

  // --- SELECTION METHODS ---

  Future<void> _pickMultipleImages() async {
    if (_postType == PostType.video) {
      setState(() {
        _mediaFiles.clear();
        _thumbnailFile = null;
      });
    }

    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _postType = PostType.image;
        _mediaFiles.addAll(pickedFiles.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _pickCameraImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      setState(() {
        if (_postType == PostType.video) _mediaFiles.clear();
        _postType = PostType.image;
        _mediaFiles.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 2),
    );
    if (pickedFile != null) {
      setState(() {
        _mediaFiles = [File(pickedFile.path)];
        _postType = PostType.video;
        _thumbnailFile = null;
      });
      await _generateThumbnail(pickedFile.path);
    }
  }

  // --- UPLOAD LOGIC ---

  Future<void> _createPost() async {
    if (_mediaFiles.isEmpty && _captionController.text.isEmpty) return;
    if (_isUploading) return;

    FocusScope.of(context).unfocus();
    setState(() => _isUploading = true);

    try {
      final cloudinary = CloudinaryPublic(
        cloudinaryCloudName,
        cloudinaryUploadPreset,
      );

      List<String> mediaUrls = [];
      String? thumbnailUrl;
      String postTypeString = _postType == PostType.video ? 'video' : 'image';

      if (_postType == PostType.video && _mediaFiles.isNotEmpty) {
        // Video Upload
        final compressedVideo = await _compressVideo(_mediaFiles.first);
        if (compressedVideo == null)
          throw Exception("Video compression failed");

        if (_thumbnailFile != null) {
          setState(() => _uploadStatus = 'Uploading thumbnail...');
          CloudinaryResponse thumbResponse = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(
              _thumbnailFile!.path,
              folder: 'thumbnails/${_user.uid}',
            ),
          );
          thumbnailUrl = thumbResponse.secureUrl;
        }

        setState(() => _uploadStatus = 'Uploading video...');
        CloudinaryResponse videoResponse = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            compressedVideo.path,
            folder: 'posts/${_user.uid}',
            resourceType: CloudinaryResourceType.Video,
          ),
        );
        mediaUrls.add(videoResponse.secureUrl);
      } else if (_postType == PostType.image && _mediaFiles.isNotEmpty) {
        // Image Upload
        for (int i = 0; i < _mediaFiles.length; i++) {
          setState(
            () =>
                _uploadStatus =
                    'Uploading photo ${i + 1}/${_mediaFiles.length}...',
          );

          final compressedImage = await _compressImage(_mediaFiles[i]);
          if (compressedImage != null) {
            CloudinaryResponse imageResponse = await cloudinary.uploadFile(
              CloudinaryFile.fromFile(
                compressedImage.path,
                folder: 'posts/${_user.uid}',
                resourceType: CloudinaryResourceType.Image,
              ),
            );
            mediaUrls.add(imageResponse.secureUrl);
          }
        }
      }

      setState(() => _uploadStatus = 'Finalizing...');

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user.uid)
              .get();
      final userData = userDoc.data() as Map<String, dynamic>;

      final postData = {
        'caption': _captionController.text.trim(),
        'userId': _user.uid,
        'userName': userData['displayName'] ?? 'User',
        'username': userData['username'] ?? '',
        'userImageUrl': userData['profilePhotoUrl'] ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'comments': 0,
        'postType': postTypeString,
        'postMediaUrl': mediaUrls.isNotEmpty ? mediaUrls.first : '',
        'postImages': mediaUrls,
        'postThumbnailUrl': thumbnailUrl,
      };

      await FirebaseFirestore.instance.collection('posts').add(postData);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post shared successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserInfo(),
                      _buildTextField(),
                      if (_mediaFiles.isNotEmpty) _buildMediaPreview(),
                    ],
                  ),
                ),
              ),
              _buildBottomActionDock(),
            ],
          ),

          if (_isUploading)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.black),
                    const SizedBox(height: 20),
                    Text(
                      _uploadStatus,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    bool isShareEnabled =
        _captionController.text.isNotEmpty || _mediaFiles.isNotEmpty;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "New Post",
        style: GoogleFonts.poppins(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: ElevatedButton(
            onPressed: isShareEnabled && !_isUploading ? _createPost : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9983F3),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: Text(
              "Post",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(_user.uid).get(),
        builder: (context, snapshot) {
          String? photoUrl;
          String name = 'Me';

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            photoUrl = data['profilePhotoUrl'];
            name = data['displayName'] ?? 'Me';
          }

          return Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl) : null,
                child:
                    photoUrl == null
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.public, size: 10, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "Public",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _captionController,
        maxLines: null,
        minLines: 2,
        // Set text color to black
        style: GoogleFonts.poppins(fontSize: 18, color: Colors.black),
        decoration: InputDecoration(
          hintText: "What's on your mind?",
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
          border: InputBorder.none,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (_mediaFiles.isEmpty) return const SizedBox.shrink();

    // 1. VIDEO PREVIEW
    if (_postType == PostType.video) {
      return Container(
        margin: const EdgeInsets.all(16),
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_thumbnailFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _thumbnailFile!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _buildRemoveButton(() {
                setState(() {
                  _mediaFiles.clear();
                  _thumbnailFile = null;
                });
              }),
            ),
          ],
        ),
      );
    }

    // 2. IMAGE CAROUSEL PREVIEW
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            itemCount: _mediaFiles.length,
            onPageChanged:
                (index) => setState(() => _currentImageIndex = index),
            controller: PageController(viewportFraction: 0.9),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: FileImage(_mediaFiles[index]),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildRemoveButton(() {
                        setState(() {
                          _mediaFiles.removeAt(index);
                          if (_currentImageIndex >= _mediaFiles.length) {
                            _currentImageIndex =
                                _mediaFiles.isEmpty
                                    ? 0
                                    : _mediaFiles.length - 1;
                          }
                        });
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Dots Indicator
        if (_mediaFiles.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_mediaFiles.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _currentImageIndex == index
                          ? Colors.blue
                          : Colors.grey.shade300,
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildRemoveButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildBottomActionDock() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          // Using MainAxisAlignment.spaceEvenly ensures icons are spread out
          // and won't overflow
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionItem(
                icon: Icons.photo_library_rounded,
                color: Colors.green.shade600,
                label: "Gallery",
                onTap: _pickMultipleImages,
              ),
              _buildActionItem(
                icon: Icons.camera_alt_rounded,
                color: Colors.blue.shade600,
                label: "Camera",
                onTap: _pickCameraImage,
              ),
              _buildActionItem(
                icon: Icons.videocam_rounded,
                color: Colors.red.shade600,
                label: "Video",
                onTap: () => _pickVideo(ImageSource.camera),
              ),
              _buildActionItem(
                icon: Icons.video_library_rounded,
                color: Colors.purple.shade600,
                label: "Clips",
                onTap: () => _pickVideo(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), // Pastel background
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
