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

  File? _mediaFile;
  File? _thumbnailFile;
  PostType _postType = PostType.none;
  bool _isUploading = false;
  String _uploadStatus = '';

  // --- HELPER METHODS ---
  Future<File?> _compressImage(File file) async {
    setState(() => _uploadStatus = 'Compressing...');
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

  Future<File?> _compressVideo(File file) async {
    setState(() => _uploadStatus = 'Compressing video...');
    final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
      file.path,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
    );
    return mediaInfo?.file;
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        _mediaFile = File(pickedFile.path);
        _postType = PostType.image;
        _thumbnailFile = null;
      });
    }
  }

  Future<void> _pickVideo() async {
    final pickedFile = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (pickedFile != null && mounted) {
      setState(() {
        _mediaFile = File(pickedFile.path);
        _postType = PostType.video;
      });
      await _generateThumbnail(pickedFile.path);
    }
  }

  void _showPickOptions() {
    // Dismiss keyboard before showing bottom sheet
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.black,
                  ),
                  title: Text(
                    'Photo Library',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.videocam_outlined,
                    color: Colors.black,
                  ),
                  title: Text(
                    'Video Library',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideo();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.black,
                  ),
                  title: Text(
                    'Take Photo',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final pickedFile = await _picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (pickedFile != null && mounted) {
                      setState(() {
                        _mediaFile = File(pickedFile.path);
                        _postType = PostType.image;
                        _thumbnailFile = null;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _createPost() async {
    if (_mediaFile == null) return;
    if (_isUploading) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cloudinary = CloudinaryPublic(
        cloudinaryCloudName,
        cloudinaryUploadPreset,
      );

      String mediaUrl;
      String? thumbnailUrl;
      String postTypeString;
      File fileToUpload;

      if (_postType == PostType.video) {
        postTypeString = 'video';
        final compressedVideo = await _compressVideo(_mediaFile!);
        if (compressedVideo == null)
          throw Exception("Video compression failed");
        fileToUpload = compressedVideo;

        if (_thumbnailFile != null) {
          setState(() => _uploadStatus = 'Uploading thumb...');
          CloudinaryResponse thumbResponse = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(
              _thumbnailFile!.path,
              folder: 'thumbnails/${user.uid}',
              resourceType: CloudinaryResourceType.Image,
            ),
          );
          thumbnailUrl = thumbResponse.secureUrl;
        }

        setState(() => _uploadStatus = 'Uploading video...');
        CloudinaryResponse videoResponse = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            fileToUpload.path,
            folder: 'posts/${user.uid}',
            resourceType: CloudinaryResourceType.Video,
          ),
        );
        mediaUrl = videoResponse.secureUrl;
      } else {
        postTypeString = 'image';
        final compressedImage = await _compressImage(_mediaFile!);
        if (compressedImage == null)
          throw Exception("Image compression failed");
        fileToUpload = compressedImage;

        setState(() => _uploadStatus = 'Uploading photo...');
        CloudinaryResponse imageResponse = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            fileToUpload.path,
            folder: 'posts/${user.uid}',
            resourceType: CloudinaryResourceType.Image,
          ),
        );
        mediaUrl = imageResponse.secureUrl;
      }

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final userData = userDoc.data() as Map<String, dynamic>;

      final postData = {
        'postType': postTypeString,
        'postMediaUrl': mediaUrl,
        'postThumbnailUrl': thumbnailUrl,
        'caption': _captionController.text.trim(),
        'userId': user.uid,
        'userName': userData['displayName'] ?? 'A User',
        'username': userData['username'] ?? '',
        'userImageUrl': userData['profilePhotoUrl'] ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'comments': 0,
      };

      final DocumentReference docRef = await FirebaseFirestore.instance
          .collection('posts')
          .add(postData);

      final Map<String, dynamic> resultData = Map<String, dynamic>.from(
        postData,
      );
      resultData['id'] = docRef.id;
      resultData['timestamp'] = Timestamp.now();

      if (!mounted) return;
      Navigator.of(context).pop(resultData);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    VideoCompress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandPurple = Color(0xFF9983F3);
    final bool hasMedia = _mediaFile != null;

    // KEY FIX: Disable automatic resizing. We will handle padding manually.
    // This stops the screen from "jumping" when the keyboard appears.
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // <--- CRITICAL FIX

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'New Post',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (!_isUploading)
            TextButton(
              onPressed: hasMedia ? _createPost : null,
              child: Text(
                'Share',
                style: GoogleFonts.poppins(
                  color: hasMedia ? brandPurple : Colors.grey.shade400,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),

      body: Stack(
        children: [
          // KEY FIX: Wrap scroll view in Padding that listens to viewInsets (keyboard height)
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              // Use simple physics to avoid spring-back jitter
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  // 1. Media Preview
                  GestureDetector(
                    onTap: _showPickOptions,
                    child: Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.width, // Square
                      color: Colors.grey.shade100,
                      child:
                          _mediaFile != null
                              ? _postType == PostType.image ||
                                      _thumbnailFile != null
                                  ? Image.file(
                                    _postType == PostType.video
                                        ? _thumbnailFile!
                                        : _mediaFile!,
                                    fit: BoxFit.cover,
                                  )
                                  : const Center(
                                    child: CircularProgressIndicator(),
                                  )
                              : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Tap to select media",
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey.shade500,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),

                  if (_mediaFile != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _showPickOptions,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text("Change"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey,
                        ),
                      ),
                    ),

                  // 2. Caption Input
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .get(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final data =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              final url = data['profilePhotoUrl'];
                              if (url != null && url.isNotEmpty) {
                                return CircleAvatar(
                                  backgroundImage: NetworkImage(url),
                                  radius: 18,
                                );
                              }
                            }
                            return const CircleAvatar(
                              child: Icon(Icons.person),
                              radius: 18,
                            );
                          },
                        ),
                        const SizedBox(width: 12),

                        // TextField
                        // Removed Flexible/Expanded. Let TextField take natural width in Row context
                        Expanded(
                          child: TextField(
                            controller: _captionController,
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 15,
                            ),
                            maxLines: null, // Grow automatically
                            minLines: 1,
                            keyboardType: TextInputType.multiline,
                            // Generous scroll padding ensures cursor stays visible
                            scrollPadding: const EdgeInsets.all(20),
                            decoration: InputDecoration(
                              hintText: 'Write a caption...',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey.shade400,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.only(
                                top: 8,
                                bottom: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // 3. Options
                  ListTile(
                    title: Text(
                      "Add Location",
                      style: GoogleFonts.poppins(fontSize: 15),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(
                      "Tag People",
                      style: GoogleFonts.poppins(fontSize: 15),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    onTap: () {},
                  ),

                  // Extra spacing at bottom
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),

          // --- Loading Overlay ---
          if (_isUploading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: brandPurple),
                    const SizedBox(height: 16),
                    Text(
                      _uploadStatus,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
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
}
