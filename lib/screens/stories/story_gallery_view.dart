// ===============================
// FILE NAME: story_gallery_view.dart
// FILE PATH: lib/screens/stories/story_gallery_view.dart
// ===============================

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image_picker/image_picker.dart';

class StoryGalleryView extends StatefulWidget {
  final Function(List<File>) onFilesSelected;
  final VoidCallback onCancel;

  const StoryGalleryView({
    super.key,
    required this.onFilesSelected,
    required this.onCancel,
  });

  @override
  State<StoryGalleryView> createState() => _StoryGalleryViewState();
}

class _StoryGalleryViewState extends State<StoryGalleryView> {
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _selectedAlbum;
  List<AssetEntity> _mediaList = [];
  final List<AssetEntity> _selectedMedia = [];

  bool _isMultiSelect = false;
  bool _isLoadingGallery = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _fetchGallery();
  }

  Future<void> _fetchGallery() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth || ps.hasAccess) {
      setState(() => _hasPermission = true);
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      );
      if (albums.isNotEmpty) {
        setState(() {
          _albums = albums;
          _selectedAlbum = albums.first;
        });
        _loadMediaForAlbum(_selectedAlbum!);
      } else {
        setState(() => _isLoadingGallery = false);
      }
    } else {
      setState(() {
        _hasPermission = false;
        _isLoadingGallery = false;
      });
    }
  }

  Future<void> _loadMediaForAlbum(AssetPathEntity album) async {
    setState(() => _isLoadingGallery = true);
    final media = await album.getAssetListPaged(page: 0, size: 100);
    setState(() {
      _mediaList = media;
      if (media.isNotEmpty && !_isMultiSelect) {
        _selectedMedia.clear();
      }
      _isLoadingGallery = false;
    });
  }

  Future<void> _openCamera() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      widget.onFilesSelected([File(picked.path)]);
    }
  }

  void _toggleSelection(AssetEntity asset) {
    setState(() {
      if (_selectedMedia.contains(asset)) {
        _selectedMedia.remove(asset);
        if (_selectedMedia.isEmpty) _isMultiSelect = false;
      } else {
        if (!_isMultiSelect) _selectedMedia.clear();
        _selectedMedia.add(asset);
        _isMultiSelect = true;
      }
    });
  }

  Future<void> _processSelections() async {
    if (_selectedMedia.isEmpty) return;
    setState(() => _isLoadingGallery = true);

    List<File> files = [];
    for (var media in _selectedMedia) {
      final file = await media.file;
      if (file != null) files.add(file);
    }

    widget.onFilesSelected(files);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.only(
        top: 20,
      ), // Give it a little breathing room at top
      child: Column(
        children: [
          // --- App Bar ---
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onCancel,
                ),
                _albums.isEmpty
                    ? const SizedBox()
                    : SizedBox(
                      width: 150,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<AssetPathEntity>(
                          isExpanded: true,
                          value: _selectedAlbum,
                          dropdownColor: Colors.grey[900],
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                          ),
                          items:
                              _albums
                                  .map(
                                    (album) => DropdownMenuItem(
                                      value: album,
                                      child: Text(
                                        album.name == "Recent"
                                            ? "Gallery"
                                            : album.name,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedAlbum = val);
                              _loadMediaForAlbum(val);
                            }
                          },
                        ),
                      ),
                    ),
                IconButton(
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                  ),
                  onPressed: _openCamera,
                ),
              ],
            ),
          ),

          // --- Large Preview Area ---
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.black,
              width: double.infinity,
              child:
                  _selectedMedia.isEmpty
                      ? const Center(
                        child: Text(
                          "Select an image",
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                      : FutureBuilder<Uint8List?>(
                        future: _selectedMedia.last.thumbnailDataWithSize(
                          const ThumbnailSize(800, 800),
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasData)
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            );
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white24,
                            ),
                          );
                        },
                      ),
            ),
          ),

          // --- Action Row ---
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap:
                      () => setState(() {
                        _isMultiSelect = !_isMultiSelect;
                        if (!_isMultiSelect) _selectedMedia.clear();
                      }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _isMultiSelect ? Colors.blueAccent : Colors.grey[800],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.content_copy,
                          size: 16,
                          color: _isMultiSelect ? Colors.white : Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Select Multiple",
                          style: GoogleFonts.poppins(
                            color:
                                _isMultiSelect ? Colors.white : Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_selectedMedia.isNotEmpty)
                  GestureDetector(
                    onTap: _processSelections,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF3E8E), Color(0xFFFF9A44)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Next",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // --- Grid Area ---
          Expanded(
            flex: 5,
            child:
                _isLoadingGallery
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                    : !_hasPermission
                    ? Center(
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
                            ),
                          ),
                          TextButton(
                            onPressed: PhotoManager.openSetting,
                            child: const Text(
                              "Open Settings",
                              style: TextStyle(color: Colors.blueAccent),
                            ),
                          ),
                        ],
                      ),
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
                        final isSelected = _selectedMedia.contains(asset);
                        final selectedIndex = _selectedMedia.indexOf(asset) + 1;

                        return GestureDetector(
                          onTap: () {
                            if (_isMultiSelect) {
                              _toggleSelection(asset);
                            } else {
                              _selectedMedia.clear();
                              _selectedMedia.add(asset);
                              _processSelections();
                            }
                          },
                          onLongPress: () {
                            if (!_isMultiSelect) {
                              setState(() => _isMultiSelect = true);
                            }
                            _toggleSelection(asset);
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              FutureBuilder<Uint8List?>(
                                future: asset.thumbnailDataWithSize(
                                  const ThumbnailSize(200, 200),
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData)
                                    return Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                    );
                                  return Container(color: Colors.grey[900]);
                                },
                              ),
                              if (isSelected)
                                Container(
                                  color: Colors.black.withOpacity(0.4),
                                  alignment: Alignment.topRight,
                                  padding: const EdgeInsets.all(8),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "$selectedIndex",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
      ),
    );
  }
}
