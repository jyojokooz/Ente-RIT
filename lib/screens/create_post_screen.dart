// ===============================
// FILE NAME: create_post_screen.dart
// FILE PATH: lib/screens/create_post_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unnecessary_import

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for PlatformException
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

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

  List<File> _mediaFiles = [];
  File? _thumbnailFile;
  PostType _postType = PostType.none;
  Map<String, dynamic>? _selectedMusic;

  bool _isUploading = false;
  // FIX: New flag to prevent double-tap crashes on Image Picker
  bool _isPickingMedia = false;

  String _uploadStatus = '';
  int _currentImageIndex = 0;

  // --- MUSIC SEARCH ---
  void _showMusicSearch() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => _MusicSearchSheet(
            onMusicSelected: (music) {
              setState(() {
                _selectedMusic = music;
              });
              Navigator.pop(context);
            },
          ),
    );
  }

  // --- HELPER: Music Overlay Button ---
  Widget _buildMusicOverlayButton() {
    bool hasMusic = _selectedMusic != null;
    return GestureDetector(
      onTap: _showMusicSearch,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasMusic ? Icons.music_note : Icons.add_circle_outline,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                hasMusic
                    ? "${_selectedMusic!['trackName']} • ${_selectedMusic!['artistName']}"
                    : "Add Music",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasMusic) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => _selectedMusic = null),
                child: const Icon(Icons.close, color: Colors.white70, size: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- COMPRESSION & SELECTION METHODS ---
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
      setState(() => _thumbnailFile = File(thumbnailPath));
    }
  }

  // --- FIXED MEDIA PICKER FUNCTIONS ---

  Future<void> _pickMultipleImages() async {
    // 1. Check if already picking
    if (_isPickingMedia) return;

    // 2. Lock
    setState(() => _isPickingMedia = true);

    try {
      if (_postType == PostType.video) {
        setState(() {
          _mediaFiles.clear();
          _thumbnailFile = null;
          _selectedMusic = null;
        });
      }

      final List<XFile> pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _postType = PostType.image;
          _mediaFiles.addAll(pickedFiles.map((x) => File(x.path)));
        });
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    } finally {
      // 3. Unlock immediately after
      if (mounted) setState(() => _isPickingMedia = false);
    }
  }

  Future<void> _pickCameraImage() async {
    if (_isPickingMedia) return;
    setState(() => _isPickingMedia = true);

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
      );
      if (pickedFile != null) {
        setState(() {
          if (_postType == PostType.video) {
            _mediaFiles.clear();
            _selectedMusic = null;
          }
          _postType = PostType.image;
          _mediaFiles.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      debugPrint("Error picking camera image: $e");
    } finally {
      if (mounted) setState(() => _isPickingMedia = false);
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    if (_isPickingMedia) return;
    setState(() => _isPickingMedia = true);

    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 2),
      );
      if (pickedFile != null) {
        setState(() {
          _mediaFiles = [File(pickedFile.path)];
          _postType = PostType.video;
          _thumbnailFile = null;
          _selectedMusic = null;
        });
        await _generateThumbnail(pickedFile.path);
      }
    } catch (e) {
      debugPrint("Error picking video: $e");
    } finally {
      if (mounted) setState(() => _isPickingMedia = false);
    }
  }

  // --- UPLOAD LOGIC ---
  Future<void> _createPost() async {
    if (_mediaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image or video to post.'),
        ),
      );
      return;
    }
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
        final compressedVideo = await _compressVideo(_mediaFiles.first);
        if (compressedVideo == null) {
          throw Exception("Video compression failed");
        }

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
      } else {
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
        if (_selectedMusic != null) 'music': _selectedMusic,
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
    bool isShareEnabled = _mediaFiles.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Text(
                "Share",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
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
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black,
                ),
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
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.black),
        decoration: InputDecoration(
          hintText: "Write a caption...",
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (_mediaFiles.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 350,
          child: Stack(
            children: [
              if (_postType == PostType.video)
                _buildVideoPreviewLayer()
              else
                _buildImageCarouselLayer(),

              Positioned(top: 12, left: 12, child: _buildMusicOverlayButton()),

              Positioned(
                top: 12,
                right: 12,
                child: _buildRemoveButton(() {
                  setState(() {
                    _mediaFiles.clear();
                    _thumbnailFile = null;
                    _selectedMusic = null;
                  });
                }),
              ),
            ],
          ),
        ),

        if (_postType == PostType.image && _mediaFiles.length > 1)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
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
          ),
      ],
    );
  }

  Widget _buildVideoPreviewLayer() {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_thumbnailFile != null)
            Image.file(
              _thumbnailFile!,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarouselLayer() {
    return PageView.builder(
      itemCount: _mediaFiles.length,
      onPageChanged: (index) => setState(() => _currentImageIndex = index),
      controller: PageController(viewportFraction: 1.0),
      itemBuilder: (context, index) {
        return Image.file(
          _mediaFiles[index],
          fit: BoxFit.cover,
          width: double.infinity,
        );
      },
    );
  }

  Widget _buildRemoveButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 18),
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
                color: color.withOpacity(0.1),
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

// --- MUSIC SEARCH SHEET WIDGET ---
class _MusicSearchSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onMusicSelected;
  const _MusicSearchSheet({required this.onMusicSelected});

  @override
  State<_MusicSearchSheet> createState() => _MusicSearchSheetState();
}

class _MusicSearchSheetState extends State<_MusicSearchSheet> {
  final _searchController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer(); // Audio Player
  List<dynamic> _songs = [];
  bool _isLoading = false;

  // Audio State
  String? _currentPreviewUrl;
  bool _isPlaying = false;
  String? _loadingPreviewUrl;

  final List<String> _trendingKeywords = [
    'Top 100',
    'Viral',
    'Pop',
    'Hip Hop',
    'Party',
    'Chill',
    'Love',
    'Workout',
  ];

  @override
  void initState() {
    super.initState();
    _loadTrendingSongs();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadTrendingSongs() {
    final randomKeyword =
        _trendingKeywords[Random().nextInt(_trendingKeywords.length)];
    _searchSongs(randomKeyword);
  }

  Future<void> _searchSongs(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isLoading = true);

    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _currentPreviewUrl = null;
    });

    try {
      final url = Uri.parse(
        'https://itunes.apple.com/search?term=$query&media=music&entity=song&limit=20',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _songs = data['results'];
        });
      }
    } catch (e) {
      debugPrint("Music API Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePreview(String url) async {
    if (_currentPreviewUrl == url && _isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      setState(() {
        _loadingPreviewUrl = url;
      });

      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));

      if (mounted) {
        setState(() {
          _loadingPreviewUrl = null;
          _currentPreviewUrl = url;
          _isPlaying = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Add Music",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: "Search songs, artists...",
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: _searchSongs,
          ),
          const SizedBox(height: 12),
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepPurple,
                      ),
                    )
                    : ListView.builder(
                      itemCount: _songs.length,
                      itemBuilder: (context, index) {
                        final song = _songs[index];
                        final previewUrl = song['previewUrl'];

                        final bool isThisSongLoading =
                            _loadingPreviewUrl == previewUrl;
                        final bool isThisSongPlaying =
                            _currentPreviewUrl == previewUrl && _isPlaying;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              song['artworkUrl100'] ?? '',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (c, e, s) => Container(
                                    color: Colors.grey,
                                    width: 50,
                                    height: 50,
                                  ),
                            ),
                          ),
                          title: Text(
                            song['trackName'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            song['artistName'],
                            maxLines: 1,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[800],
                            ),
                          ),

                          trailing: SizedBox(
                            width: 40,
                            height: 40,
                            child:
                                isThisSongLoading
                                    ? const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.deepPurple,
                                      ),
                                    )
                                    : IconButton(
                                      icon: Icon(
                                        isThisSongPlaying
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_fill,
                                        color:
                                            isThisSongPlaying
                                                ? Colors.deepPurple
                                                : Colors.grey[400],
                                        size: 32,
                                      ),
                                      onPressed:
                                          () => _togglePreview(previewUrl),
                                    ),
                          ),

                          onTap: () {
                            _audioPlayer.stop();
                            widget.onMusicSelected({
                              'trackName': song['trackName'],
                              'artistName': song['artistName'],
                              'previewUrl': song['previewUrl'],
                              'artworkUrl': song['artworkUrl100'],
                            });
                          },
                        );
                      },
                    ),
          ),

          if (_currentPreviewUrl != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.graphic_eq,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Previewing 30s clip (Tap song to select)",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
