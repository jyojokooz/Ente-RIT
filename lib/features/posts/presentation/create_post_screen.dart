// ===============================
// FILE NAME: create_post_screen.dart
// FILE PATH: lib/features/posts/presentation/create_post_screen.dart
// ===============================

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_compress/video_compress.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Import the split components from the subfolder
import 'package:my_project/features/posts/presentation/widgets/step1_media_picker.dart';
import 'package:my_project/features/posts/presentation/widgets/step2_media_editor.dart';
import 'package:my_project/features/posts/presentation/widgets/step3_post_details.dart';

// Define the enum here so all steps can access it
enum PostType { image, video, none }

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _user = FirebaseAuth.instance.currentUser!;

  // --- GLOBAL POST STATE ---
  int _currentStep = 0;
  List<File> _mediaFiles = [];
  File? _thumbnailFile;
  PostType _postType = PostType.none;

  final TextEditingController _captionController = TextEditingController();
  Map<String, dynamic>? _selectedMusic;
  String _location = '';
  List<String> _taggedUsers = [];
  bool _disableComments = false;

  // FIX: This variable is now saved to Firestore in _createPost
  String _selectedFilter = '';

  bool _isUploading = false;
  String _uploadStatus = '';

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  // --- COMPRESSION HELPERS ---
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

  // --- UPLOAD LOGIC ---
  Future<void> _createPost() async {
    if (_isUploading) return;
    FocusScope.of(context).unfocus();
    setState(() => _isUploading = true);

    try {
      List<String> mediaUrls = [];
      String? thumbnailUrl;
      String postTypeString = _postType == PostType.video ? 'video' : 'image';

      // 1. Upload Video
      if (_postType == PostType.video && _mediaFiles.isNotEmpty) {
        final compressedVideo = await _compressVideo(_mediaFiles.first);
        if (compressedVideo == null) {
          throw Exception("Video compression failed");
        }

        if (_thumbnailFile != null) {
          setState(() => _uploadStatus = 'Uploading thumbnail...');
          final thumbRef = FirebaseStorage.instance.ref().child(
            'thumbnails/${_user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          await thumbRef.putFile(_thumbnailFile!);
          thumbnailUrl = await thumbRef.getDownloadURL();
        }

        setState(() => _uploadStatus = 'Uploading video...');
        final videoRef = FirebaseStorage.instance.ref().child(
          'posts/${_user.uid}/${DateTime.now().millisecondsSinceEpoch}.mp4',
        );
        await videoRef.putFile(
          compressedVideo,
          SettableMetadata(contentType: 'video/mp4'),
        );
        mediaUrls.add(await videoRef.getDownloadURL());
      }
      // 2. Upload Images
      else if (_mediaFiles.isNotEmpty) {
        for (int i = 0; i < _mediaFiles.length; i++) {
          setState(
            () =>
                _uploadStatus =
                    'Uploading photo ${i + 1}/${_mediaFiles.length}...',
          );
          final compressedImage = await _compressImage(_mediaFiles[i]);
          if (compressedImage != null) {
            final imgRef = FirebaseStorage.instance.ref().child(
              'posts/${_user.uid}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
            );
            await imgRef.putFile(compressedImage);
            // Note: Visual filters from Step 2 are not currently baked into the file here.
            // If baking is implemented in Step 2, the passed `compressedImage` will already contain the edits.
            mediaUrls.add(await imgRef.getDownloadURL());
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

      // 3. Save to Firestore
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
        'location': _location,
        'taggedUsers': _taggedUsers,
        'commentsDisabled': _disableComments,
        'filter': _selectedFilter, // <-- FIX: Using the variable here
        if (_selectedMusic != null) 'music': _selectedMusic,
        // Save the author's current privacy status to the post
        'isAuthorPrivate': userData['isPrivate'] ?? false,
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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // --- STEP MANAGER ---
            if (_currentStep == 0)
              Step1MediaPicker(
                onMediaPicked: (files, type, thumb) {
                  setState(() {
                    _mediaFiles = files;
                    _postType = type;
                    _thumbnailFile = thumb;
                    _currentStep = 1; // Go to Editor
                  });
                },
                onClose: () => Navigator.pop(context),
              ),

            if (_currentStep == 1)
              Step2MediaEditor(
                mediaFiles: _mediaFiles,
                postType: _postType,
                thumbnailFile: _thumbnailFile,
                onBack:
                    () => setState(() {
                      _mediaFiles.clear();
                      _currentStep = 0;
                    }),
                onNext: (editedFiles, filterEffect) {
                  setState(() {
                    _mediaFiles = editedFiles;
                    _selectedFilter =
                        filterEffect; // Capturing the selected filter
                    _currentStep = 2; // Go to Details
                  });
                },
              ),

            if (_currentStep == 2)
              Step3PostDetails(
                captionController: _captionController,
                postType: _postType,
                mediaFiles: _mediaFiles,
                thumbnailFile: _thumbnailFile,
                location: _location,
                taggedUsers: _taggedUsers,
                disableComments: _disableComments,
                selectedMusic: _selectedMusic,
                onBack: () => setState(() => _currentStep = 1),
                onShare: _createPost,
                onUpdateLocation: (loc) => setState(() => _location = loc),
                onUpdateTags: (tags) => setState(() => _taggedUsers = tags),
                onUpdateSettings:
                    (disabled) => setState(() => _disableComments = disabled),
                onUpdateMusic:
                    (music) => setState(() => _selectedMusic = music),
              ),

            // --- LOADING OVERLAY ---
            if (_isUploading)
              Container(
                color: Colors.black.withAlpha(204), // Replaces withOpacity(0.8)
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 20),
                      Text(
                        _uploadStatus,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
