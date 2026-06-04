// ===============================
// FILE NAME: step1_media_picker.dart
// FILE PATH: lib/features/posts/presentation/widgets/step1_media_picker.dart
// ===============================

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_thumbnail/video_thumbnail.dart'
    as vt; // Aliased to prevent conflicts
import 'package:path_provider/path_provider.dart';
import 'package:my_project/features/posts/presentation/create_post_screen.dart';

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

  // --- PAGINATION STATE ---
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final int _pageSize = 60; // Load 60 items at a time for instant UI response

  final LinearGradient _brandGradient = const LinearGradient(
    colors: [Color(0xFF9983F3), Color(0xFFFF4B72)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _fetchAlbums();

    // Listen to scroll events to load more images
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreMedia();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchAlbums() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();

    if (!mounted) return; // Check if user left screen during permission prompt

    if (ps.isAuth || ps.hasAccess) {
      setState(() => _hasPermission = true);

      final FilterOptionGroup filterOptionGroup = FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        videoOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
      );

      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        filterOption: filterOptionGroup,
      );

      if (!mounted) return; // Guard against unmounted state

      if (albums.isNotEmpty) {
        setState(() {
          _albums = albums;
          _selectedAlbum = albums.first;
        });
        _loadMediaForAlbum(_selectedAlbum!);
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      if (!mounted) return;
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMediaForAlbum(AssetPathEntity album) async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _mediaList.clear();
      _hasMore = true;
    });

    List<AssetEntity> media = await album.getAssetListPaged(
      page: _currentPage,
      size: _pageSize,
    );

    if (!mounted) return; // Guard against unmounted state

    setState(() {
      _mediaList = media;
      if (media.isNotEmpty) {
        _selectedMedia = media[0];
      } else {
        _selectedMedia = null;
      }
      _hasMore = media.length == _pageSize;
      _isLoading = false;
    });
  }

  Future<void> _loadMoreMedia() async {
    if (_isLoadingMore || !_hasMore || _selectedAlbum == null) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;

    List<AssetEntity> moreMedia = await _selectedAlbum!.getAssetListPaged(
      page: _currentPage,
      size: _pageSize,
    );

    if (!mounted) return; // Guard against unmounted state

    setState(() {
      _mediaList.addAll(moreMedia);
      _hasMore = moreMedia.length == _pageSize;
      _isLoadingMore = false;
    });
  }

  Future<void> _openCamera() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null && mounted) {
      widget.onMediaPicked([File(pickedFile.path)], PostType.image, null);
    }
  }

  Future<void> _handleNext() async {
    if (_selectedMedia == null || _isProcessingNext) return;

    setState(() => _isProcessingNext = true);
    final File? file = await _selectedMedia!.file;

    if (!mounted) return; // Guard against unmounted state

    if (file == null) {
      setState(() => _isProcessingNext = false);
      return;
    }

    if (_selectedMedia!.type == AssetType.video) {
      try {
        final tempDir = await getTemporaryDirectory();
        final thumbPath = await vt.VideoThumbnail.thumbnailFile(
          video: file.path,
          thumbnailPath: tempDir.path,
          imageFormat: vt.ImageFormat.JPEG,
          quality: 75,
        );

        if (!mounted) return; // Guard against unmounted state

        widget.onMediaPicked(
          [file],
          PostType.video,
          thumbPath != null ? File(thumbPath) : null,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isProcessingNext = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to process video: $e")));
      }
    } else {
      widget.onMediaPicked([file], PostType.image, null);
    }
  }

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
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
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
                GestureDetector(
                  onTap:
                      _isProcessingNext || _selectedMedia == null
                          ? null
                          : _handleNext,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient:
                          _isProcessingNext || _selectedMedia == null
                              ? null
                              : _brandGradient,
                      color:
                          _isProcessingNext || _selectedMedia == null
                              ? Colors.white24
                              : null,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child:
                        _isProcessingNext
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              "Next",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
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
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: PhotoManager.openSetting,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9983F3),
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
              height: MediaQuery.of(context).size.width,
              width: double.infinity,
              color: Colors.black,
              child:
                  _selectedMedia == null
                      ? Center(
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(
                                  color: Color(0xFF9983F3),
                                )
                                : const Text(
                                  "No media found",
                                  style: TextStyle(color: Colors.white54),
                                ),
                      )
                      : Stack(
                        fit: StackFit.expand,
                        children: [
                          FutureBuilder<Uint8List?>(
                            key: ValueKey(_selectedMedia!.id),
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

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.black,
              child: Row(
                children: [
                  // --- ALBUM DROPDOWN ---
                  if (_albums.isNotEmpty)
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<AssetPathEntity>(
                          isExpanded: true,
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                    ),

                  const SizedBox(width: 16),

                  GestureDetector(
                    onTap: _openCamera,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF9983F3), Color(0xFFFF4B72)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
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
                        child: CircularProgressIndicator(
                          color: Color(0xFF9983F3),
                        ),
                      )
                      : GridView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 2,
                              mainAxisSpacing: 2,
                            ),
                        itemCount: _mediaList.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _mediaList.length) {
                            return const Center(
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }

                          final asset = _mediaList[index];
                          final isSelected = _selectedMedia?.id == asset.id;

                          return GestureDetector(
                            onTap: () => setState(() => _selectedMedia = asset),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Fast loading low-res thumbnail for the grid
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

                                if (isSelected)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(100),
                                      border: Border.all(
                                        color: const Color(0xFFFF4B72),
                                        width: 3,
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
