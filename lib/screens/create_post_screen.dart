// ===============================
// FILE NAME: create_post_screen.dart
// FILE PATH: lib/screens/create_post_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  bool _isPickingMedia = false;

  String _uploadStatus = '';
  int _currentImageIndex = 0;

  // --- MUSIC SEARCH ---
  void _showMusicSearch() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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

  Widget _buildMusicOverlayButton() {
    bool hasMusic = _selectedMusic != null;
    return GestureDetector(
      onTap: _showMusicSearch,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6), // Glassmorphic feel
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasMusic
                  ? Icons.music_note_rounded
                  : Icons.add_circle_outline_rounded,
              color: Colors.white,
              size: 16,
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
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _selectedMusic = null),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- COMPRESSION LOGIC ---
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

  // --- MEDIA PICKERS ---
  Future<void> _pickMultipleImages() async {
    if (_isPickingMedia) return;
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
    if (_mediaFiles.isEmpty && _captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add media or write something to post.'),
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
      } else if (_mediaFiles.isNotEmpty) {
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Exact colors matching design
    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedTextColor = isDark ? Colors.white54 : Colors.grey.shade600;

    bool isShareEnabled =
        _mediaFiles.isNotEmpty || _captionController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Create Post",
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient:
                    (isShareEnabled && !_isUploading)
                        ? const LinearGradient(
                          colors: [Color(0xFFFF3E8E), Color(0xFFFF9A44)],
                        )
                        : null,
                color:
                    (isShareEnabled && !_isUploading)
                        ? null
                        : (isDark ? Colors.white10 : Colors.grey.shade300),
              ),
              child: ElevatedButton(
                onPressed: isShareEnabled && !_isUploading ? _createPost : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  "Share",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
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
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- AUTHOR INFO & INPUT CARD ---
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildUserInfo(textColor, isDark),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _captionController,
                              maxLines: null,
                              minLines: 3,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: textColor,
                              ),
                              onChanged:
                                  (_) => setState(
                                    () {},
                                  ), // To trigger share button state
                              decoration: InputDecoration(
                                hintText: "What's bothering you?",
                                hintStyle: GoogleFonts.poppins(
                                  color: mutedTextColor,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- MEDIA PREVIEW ---
                      if (_mediaFiles.isNotEmpty)
                        _buildMediaPreview(isDark, cardColor),
                      const SizedBox(height: 100), // Space for floating dock
                    ],
                  ),
                ),
              ),
            ],
          ),

          // --- FLOATING ACTION DOCK ---
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _buildBottomActionDock(cardColor, textColor, isDark),
          ),

          // --- LOADING OVERLAY ---
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFFFF3E8E)),
                      const SizedBox(height: 20),
                      Text(
                        _uploadStatus,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(Color textColor, bool isDark) {
    return FutureBuilder<DocumentSnapshot>(
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
              backgroundColor:
                  isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              backgroundImage:
                  photoUrl != null && photoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(photoUrl)
                      : null,
              child:
                  (photoUrl == null || photoUrl.isEmpty)
                      ? Icon(
                        Icons.person,
                        color: isDark ? Colors.white54 : Colors.grey,
                      )
                      : null,
            ),
            const SizedBox(width: 12),
            Text(
              name,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMediaPreview(bool isDark, Color cardColor) {
    return Column(
      children: [
        Container(
          height: 350,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30), // Deep curves
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_postType == PostType.video)
                  _buildVideoPreviewLayer(isDark)
                else
                  _buildImageCarouselLayer(isDark),

                Positioned(
                  top: 16,
                  left: 16,
                  child: _buildMusicOverlayButton(),
                ),

                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap:
                        () => setState(() {
                          _mediaFiles.clear();
                          _thumbnailFile = null;
                          _selectedMusic = null;
                        }),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_postType == PostType.image && _mediaFiles.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_mediaFiles.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color:
                        _currentImageIndex == index
                            ? const Color(0xFFFF3E8E)
                            : (isDark ? Colors.white24 : Colors.grey.shade300),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoPreviewLayer(bool isDark) {
    return Container(
      color: isDark ? Colors.grey.shade900 : Colors.black,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          if (_thumbnailFile != null)
            Image.file(_thumbnailFile!, fit: BoxFit.cover),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarouselLayer(bool isDark) {
    return PageView.builder(
      itemCount: _mediaFiles.length,
      onPageChanged: (index) => setState(() => _currentImageIndex = index),
      controller: PageController(viewportFraction: 1.0),
      itemBuilder: (context, index) {
        return Image.file(_mediaFiles[index], fit: BoxFit.cover);
      },
    );
  }

  Widget _buildBottomActionDock(Color cardColor, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDockButton(
            Icons.photo_library_rounded,
            "Gallery",
            const Color(0xFF00C6FB),
            _pickMultipleImages,
            isDark,
          ),
          _buildDockButton(
            Icons.camera_alt_rounded,
            "Camera",
            const Color(0xFFFF9A44),
            _pickCameraImage,
            isDark,
          ),
          _buildDockButton(
            Icons.videocam_rounded,
            "Video",
            const Color(0xFFFF3E8E),
            () => _pickVideo(ImageSource.camera),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildDockButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15), // Tinted background
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<dynamic> _songs = [];
  bool _isLoading = false;

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
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
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
        setState(() => _songs = data['results']);
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
      setState(() => _loadingPreviewUrl = url);
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = theme.colorScheme.onSurface;
    final mutedColor = isDark ? Colors.white54 : Colors.black54;
    final brandColor = const Color(0xFFFF3E8E);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Add Music",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: "Search songs, artists...",
              hintStyle: TextStyle(color: mutedColor),
              prefixIcon: Icon(Icons.search, color: mutedColor),
              filled: true,
              fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: _searchSongs,
          ),
          const SizedBox(height: 12),
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(color: brandColor),
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

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
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
                                color: textColor,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              song['artistName'],
                              maxLines: 1,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: mutedColor,
                              ),
                            ),
                            trailing: SizedBox(
                              width: 40,
                              height: 40,
                              child:
                                  isThisSongLoading
                                      ? Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: brandColor,
                                        ),
                                      )
                                      : IconButton(
                                        icon: Icon(
                                          isThisSongPlaying
                                              ? Icons.pause_circle_filled
                                              : Icons.play_circle_fill,
                                          color:
                                              isThisSongPlaying
                                                  ? brandColor
                                                  : mutedColor,
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
                          ),
                        );
                      },
                    ),
          ),
          if (_currentPreviewUrl != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.graphic_eq, color: brandColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Previewing 30s clip (Tap song to select)",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: mutedColor,
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
