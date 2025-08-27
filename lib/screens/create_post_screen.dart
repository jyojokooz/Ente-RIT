import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // <-- FIX: Corrected import path
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

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
    if (mounted) setState(() => _uploadStatus = 'Compressing video...');
    final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
      file.path,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
    );
    return mediaInfo?.file;
  }

  Future<void> _pickImage() async {
    Navigator.of(context).pop();
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery); // <-- FIX: Corrected 'ImageSource'
    if (pickedFile != null && mounted) {
      setState(() {
        _mediaFile = File(pickedFile.path);
        _postType = PostType.image;
        _thumbnailFile = null;
      });
    }
  }

  Future<void> _pickVideo() async {
    Navigator.of(context).pop();
    final pickedFile = await _picker.pickVideo(
      source: ImageSource.gallery, // <-- FIX: Corrected 'ImageSource'
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Pick Image from Gallery', style: TextStyle(color: Colors.white)),
              onTap: _pickImage,
            ),
            ListTile(
              leading: const Icon(Icons.video_library, color: Colors.white),
              title: const Text('Pick Video from Gallery', style: TextStyle(color: Colors.white)),
              onTap: _pickVideo,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPost() async {
    if (_mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image or video.')));
      return;
    }
    if (_isUploading) {
      return;
    }

    if (mounted) setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cloudinary = CloudinaryPublic(cloudinaryCloudName, cloudinaryUploadPreset);

      String mediaUrl;
      String? thumbnailUrl;
      String postTypeString;

      if (_postType == PostType.video) {
        postTypeString = 'video';
        final compressedVideo = await _compressVideo(_mediaFile!);
        if (compressedVideo == null) {
          throw Exception("Video compression failed");
        }

        if (_thumbnailFile != null) {
          if (mounted) setState(() => _uploadStatus = 'Uploading thumbnail...');
          CloudinaryResponse thumbResponse = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(
              _thumbnailFile!.path,
              folder: 'thumbnails/${user.uid}',
              resourceType: CloudinaryResourceType.Image,
            ),
          );
          thumbnailUrl = thumbResponse.secureUrl;
        }

        if (mounted) setState(() => _uploadStatus = 'Uploading video...');
        CloudinaryResponse videoResponse = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            compressedVideo.path,
            folder: 'posts/${user.uid}',
            resourceType: CloudinaryResourceType.Video,
          ),
        );
        mediaUrl = videoResponse.secureUrl;
      } else {
        postTypeString = 'image';
        if (mounted) setState(() => _uploadStatus = 'Uploading image...');
        CloudinaryResponse imageResponse = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            _mediaFile!.path,
            folder: 'posts/${user.uid}',
            resourceType: CloudinaryResourceType.Image,
          ),
        );
        mediaUrl = imageResponse.secureUrl;
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
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
      await FirebaseFirestore.instance.collection('posts').add(postData);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create post: ${e.toString()}')));
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          'Create New Post',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _createPost,
              child: Text(
                'Post',
                style: GoogleFonts.poppins(
                  color: Colors.yellow,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showPickOptions,
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(15),
                    image: _mediaFile != null && (_postType == PostType.image || _thumbnailFile != null)
                        ? DecorationImage(
                            image: FileImage(_postType == PostType.video ? _thumbnailFile! : _mediaFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _mediaFile == null
                      ? const Center(
                          child: Icon(
                            Icons.add_a_photo_outlined,
                            size: 60,
                            color: Colors.white70,
                          ),
                        )
                      : (_postType == PostType.video
                          ? const Center(
                              child: Icon(Icons.play_circle_fill_outlined, size: 80, color: Colors.white70))
                          : null),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write a caption...',
                hintStyle: const TextStyle(color: Colors.white70),
                fillColor: Colors.grey.shade900,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_isUploading) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: Colors.yellow),
              const SizedBox(height: 10),
              Text(_uploadStatus, style: const TextStyle(color: Colors.white70)),
            ]
          ],
        ),
      ),
    );
  }
}