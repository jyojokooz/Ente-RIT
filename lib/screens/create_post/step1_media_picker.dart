import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../create_post_screen.dart'; // Adjust path to the PostType enum

class Step1MediaPicker extends StatefulWidget {
  final Function(List<File> files, PostType type, File? thumbnail)
  onMediaPicked;
  final VoidCallback onClose;

  const Step1MediaPicker({
    super.key,
    required this.onMediaPicked,
    required this.onClose,
  });

  @override
  State<Step1MediaPicker> createState() => _Step1MediaPickerState();
}

class _Step1MediaPickerState extends State<Step1MediaPicker> {
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _selectedAlbum;
  List<AssetEntity> _mediaList = [];
  AssetEntity? _selectedMedia;

  bool _isLoading = true;
  bool _hasPermission = false;
  bool _isProcessingNext = false;

  @override
  void initState() {
    super.initState();
    _fetchAlbums();
  }

  // --- FETCH ALBUMS DIRECTLY FROM DEVICE ---
  Future<void> _fetchAlbums() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();

    if (ps.isAuth || ps.hasAccess) {
      setState(() => _hasPermission = true);

      // Removed constraints to ensure ALL videos (even short ones) are fetched
      final FilterOptionGroup filterOptionGroup = FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        videoOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
      );

      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.common, // Common fetches BOTH Images and Videos
        filterOption: filterOptionGroup,
      );

      if (albums.isNotEmpty) {
        setState(() {
          _albums = albums;
          _selectedAlbum = albums.first; // Usually "Recent"
        });
        _loadMediaForAlbum(_selectedAlbum!);
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
    }
  }

  // --- LOAD MEDIA FOR SELECTED ALBUM ---
  Future<void> _loadMediaForAlbum(AssetPathEntity album) async {
    setState(() => _isLoading = true);

    // Fetch up to 100 items from this specific album
    List<AssetEntity> media = await album.getAssetListPaged(page: 0, size: 100);

    setState(() {
      _mediaList = media;
      if (media.isNotEmpty) {
        _selectedMedia = media[0]; // Preview the first item
      } else {
        _selectedMedia = null;
      }
      _isLoading = false;
    });
  }

  // --- HANDLE LIVE CAMERA CAPTURE ---
  Future<void> _openCamera() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      widget.onMediaPicked([File(pickedFile.path)], PostType.image, null);
    }
  }

  // --- HANDLE NEXT BUTTON (Process Selected Media) ---
  Future<void> _handleNext() async {
    if (_selectedMedia == null || _isProcessingNext) return;

    setState(() => _isProcessingNext = true);

    final File? file = await _selectedMedia!.file;

    if (file == null) {
      setState(() => _isProcessingNext = false);
      return;
    }

    if (_selectedMedia!.type == AssetType.video) {
      // Generate a thumbnail for the video
      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: file.path,
        imageFormat: ImageFormat.JPEG,
        quality: 75,
      );
      widget.onMediaPicked(
        [file],
        PostType.video,
        thumbPath != null ? File(thumbPath) : null,
      );
    } else {
      widget.onMediaPicked([file], PostType.image, null);
    }
  }

  // Helper to format video duration (e.g., 01:23)
  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final secs = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // --- 1. APP BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, size: 28, color: Colors.white),
                  onPressed: widget.onClose,
                ),
                Text(
                  "New Post",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed:
                      _isProcessingNext || _selectedMedia == null
                          ? null
                          : _handleNext,
                  child:
                      _isProcessingNext
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.blueAccent,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            "Next",
                            style: GoogleFonts.poppins(
                              color: Colors.blueAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ],
            ),
          ),

          // --- 2. PERMISSION DENIED STATE ---
          if (!_isLoading && !_hasPermission)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.photo_library_outlined,
                      size: 60,
                      color: Colors.white54,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Gallery Access Required",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Please enable gallery permissions\nin your device settings.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.white54),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: PhotoManager.openSetting,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                      child: const Text(
                        "Open Settings",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            )
          // --- 3. GALLERY UI ---
          else ...[
            // Top Preview Area
            Container(
              height: MediaQuery.of(context).size.width, // Square aspect ratio
              width: double.infinity,
              color: Colors.black,
              child:
                  _selectedMedia == null
                      ? Center(
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  "No media found",
                                  style: TextStyle(color: Colors.white54),
                                ),
                      )
                      : Stack(
                        fit: StackFit.expand,
                        children: [
                          // Load High-Res preview of selected image/video
                          FutureBuilder<Uint8List?>(
                            key: ValueKey(
                              _selectedMedia!.id,
                            ), // Prevents flicker
                            future: _selectedMedia!.thumbnailDataWithSize(
                              const ThumbnailSize(800, 800),
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                );
                              }
                              return Container(color: Colors.grey.shade900);
                            },
                          ),
                          // Video Play Icon Overlay
                          if (_selectedMedia!.type == AssetType.video)
                            const Center(
                              child: Icon(
                                Icons.play_circle_fill,
                                color: Colors.white,
                                size: 60,
                              ),
                            ),
                        ],
                      ),
            ),

            // Album Selector & Camera Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.black,
              child: Row(
                children: [
                  // --- ALBUM DROPDOWN ---
                  if (_albums.isNotEmpty)
                    DropdownButtonHideUnderline(
                      child: DropdownButton<AssetPathEntity>(
                        value: _selectedAlbum,
                        dropdownColor: Colors.grey.shade900,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                        ),
                        items:
                            _albums.map((album) {
                              return DropdownMenuItem(
                                value: album,
                                child: Text(
                                  album.name == "Recent"
                                      ? "Gallery"
                                      : album.name,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                        onChanged: (album) {
                          if (album != null && album != _selectedAlbum) {
                            setState(() => _selectedAlbum = album);
                            _loadMediaForAlbum(album);
                          }
                        },
                      ),
                    ),

                  const Spacer(),
                  GestureDetector(
                    onTap: _openCamera,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Grid Area
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                      : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 2,
                              mainAxisSpacing: 2,
                            ),
                        itemCount: _mediaList.length,
                        itemBuilder: (context, index) {
                          final asset = _mediaList[index];
                          final isSelected = _selectedMedia?.id == asset.id;

                          return GestureDetector(
                            onTap: () => setState(() => _selectedMedia = asset),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Low-Res Thumbnail for grid performance
                                FutureBuilder<Uint8List?>(
                                  future: asset.thumbnailDataWithSize(
                                    const ThumbnailSize(200, 200),
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                      );
                                    }
                                    return Container(
                                      color: Colors.grey.shade800,
                                    );
                                  },
                                ),

                                // Video duration overlay
                                if (asset.type == AssetType.video)
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Text(
                                      _formatDuration(
                                        asset.videoDuration.inSeconds,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black,
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Selection Overlay (Fixing withOpacity deprecation using withAlpha)
                                if (isSelected)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(
                                        76,
                                      ), // ~0.3 opacity
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ],
      ),
    );
  }
}
