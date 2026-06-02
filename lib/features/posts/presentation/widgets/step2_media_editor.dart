// ===============================
// FILE PATH: lib/screens/create_post/step2_media_editor.dart
// ===============================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:my_project/features/posts/presentation/create_post_screen.dart';

class Step2MediaEditor extends StatefulWidget {
  final List<File> mediaFiles;
  final PostType postType;
  final File? thumbnailFile;
  final VoidCallback onBack;
  final Function(List<File> files, String cloudinaryFilter) onNext;

  const Step2MediaEditor({
    super.key,
    required this.mediaFiles,
    required this.postType,
    this.thumbnailFile,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<Step2MediaEditor> createState() => _Step2MediaEditorState();
}

class _Step2MediaEditorState extends State<Step2MediaEditor> {
  late List<File> _currentFiles;
  final int _currentIndex = 0;
  int _selectedTab = 0;

  // The Pink-Violet Brand Gradient
  final LinearGradient _brandGradient = const LinearGradient(
    colors: [Color(0xFF9983F3), Color(0xFFFF4B72)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Expanded Filter List
  final List<Map<String, dynamic>> _filters = [
    {
      'name': 'Normal',
      'matrix': <double>[
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ],
      'effect': '',
    },
    {
      'name': 'B&W',
      'matrix': <double>[
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ],
      'effect': 'e_grayscale',
    },
    {
      'name': 'Sepia',
      'matrix': <double>[
        0.393,
        0.769,
        0.189,
        0,
        0,
        0.349,
        0.686,
        0.168,
        0,
        0,
        0.272,
        0.534,
        0.131,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ],
      'effect': 'e_sepia',
    },
    {
      'name': 'Warm',
      'matrix': <double>[
        1.2,
        0,
        0,
        0,
        10,
        0,
        1.1,
        0,
        0,
        5,
        0,
        0,
        0.9,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ],
      'effect': 'e_art:peacock',
    },
    {
      'name': 'Cool',
      'matrix': <double>[
        0.9,
        0,
        0,
        0,
        0,
        0,
        1.0,
        0,
        0,
        10,
        0,
        0,
        1.2,
        0,
        20,
        0,
        0,
        0,
        1,
        0,
      ],
      'effect': 'e_art:frost',
    },
    {
      'name': 'Vintage',
      'matrix': <double>[
        0.9,
        0.5,
        0.1,
        0,
        0,
        0.3,
        0.8,
        0.1,
        0,
        0,
        0.2,
        0.3,
        0.5,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ],
      'effect': 'e_art:incognito',
    },
    {
      'name': 'Fade',
      'matrix': <double>[
        0.8,
        0,
        0,
        0,
        40,
        0,
        0.8,
        0,
        0,
        40,
        0,
        0,
        0.8,
        0,
        40,
        0,
        0,
        0,
        1,
        0,
      ],
      'effect': 'e_brightness:20',
    },
    {
      'name': 'Invert',
      'matrix': <double>[
        -1,
        0,
        0,
        0,
        255,
        0,
        -1,
        0,
        0,
        255,
        0,
        0,
        -1,
        0,
        255,
        0,
        0,
        0,
        1,
        0,
      ],
      'effect': 'e_negate',
    },
  ];

  int _selectedFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentFiles = List.from(widget.mediaFiles);
  }

  Future<void> _cropCurrentImage() async {
    if (widget.postType == PostType.video) return;

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _currentFiles[_currentIndex].path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Zoom & Crop',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            // Brand pink highlight for the active crop tool
            activeControlsWidgetColor: const Color(0xFFFF4B72),
            backgroundColor: Colors.black,
            // Darkens the area outside the crop box for that premium Instagram feel
            dimmedLayerColor: Colors.black.withOpacity(0.8),
            cropFrameColor: Colors.white,
            cropGridColor: Colors.white54,
            initAspectRatio: CropAspectRatioPreset.square, // Default to 1:1
            lockAspectRatio:
                false, // CRITICAL: Allows freeform two-finger pinch-to-zoom and pan
            hideBottomControls:
                false, // CRITICAL: Shows the aspect ratio icons (small rectangles)
            aspectRatioPresets: [
              CropAspectRatioPreset.square, // 1:1 (Instagram Square)
              CropAspectRatioPreset.original, // Freeform / Original
              CropAspectRatioPreset.ratio5x4, // 5:4 / 4:5 (Instagram Portrait)
              CropAspectRatioPreset.ratio4x3, // Standard Portrait/Landscape
              CropAspectRatioPreset.ratio16x9, // Widescreen
              CropAspectRatioPreset.ratio7x5, // Classic Photo
            ],
          ),
          IOSUiSettings(
            title: 'Zoom & Crop',
            aspectRatioLockEnabled: false, // Allows pinch-to-zoom
            resetAspectRatioEnabled: true,
            aspectRatioPickerButtonHidden:
                false, // CRITICAL: Shows the aspect ratio icons on iOS
            aspectRatioPresets: [
              CropAspectRatioPreset.square, // 1:1
              CropAspectRatioPreset.original, // Freeform
              CropAspectRatioPreset.ratio5x4, // 4:5 Portrait
              CropAspectRatioPreset.ratio4x3, // 4:3
              CropAspectRatioPreset.ratio16x9, // 16:9
            ],
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _currentFiles[_currentIndex] = File(croppedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Adjustment failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 24,
                    color: Colors.white,
                  ),
                  onPressed: widget.onBack,
                ),
                Expanded(
                  child: Text(
                    "Edit Media",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap:
                      () => widget.onNext(
                        _currentFiles,
                        _filters[_selectedFilterIndex]['effect'],
                      ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: _brandGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
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

          Expanded(
            child: Container(
              color: const Color(0xFF161618),
              child: Center(
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(
                    _filters[_selectedFilterIndex]['matrix'],
                  ),
                  child:
                      widget.postType == PostType.video
                          ? Stack(
                            fit: StackFit.expand,
                            children: [
                              if (widget.thumbnailFile != null)
                                Image.file(
                                  widget.thumbnailFile!,
                                  fit: BoxFit.contain,
                                ),
                              Container(color: Colors.black45),
                              const Center(
                                child: Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 80,
                                ),
                              ),
                            ],
                          )
                          : Image.file(
                            _currentFiles[_currentIndex],
                            fit: BoxFit.contain,
                          ),
                ),
              ),
            ),
          ),

          Container(
            color: Colors.black,
            child: Column(
              children: [
                SizedBox(
                  height: 120,
                  child:
                      widget.postType == PostType.video
                          ? Center(
                            child: Text(
                              "Video trimming coming soon.",
                              style: GoogleFonts.poppins(color: Colors.white54),
                            ),
                          )
                          : _selectedTab == 0
                          ? _buildFilterSelector()
                          : _buildEditControls(),
                ),
                if (widget.postType == PostType.image)
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white.withAlpha(25)),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildBottomTab(0, "Filters"),
                        _buildBottomTab(1, "Crop & Resize"),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSelector() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _filters.length,
      itemBuilder: (context, index) {
        final isSelected = _selectedFilterIndex == index;
        return GestureDetector(
          onTap: () => setState(() => _selectedFilterIndex = index),
          child: Container(
            width: 70,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border:
                          isSelected
                              ? Border.all(
                                color: const Color(0xFFFF4B72),
                                width: 2.5,
                              )
                              : Border.all(
                                color: Colors.transparent,
                                width: 2.5,
                              ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.matrix(
                          _filters[index]['matrix'],
                        ),
                        child: Image.file(
                          _currentFiles[_currentIndex],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _filters[index]['name'],
                  style: GoogleFonts.poppins(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditControls() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _cropCurrentImage,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF9983F3), Color(0xFFFF4B72)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.crop_rotate_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Crop & Rotate",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTab(int index, String title) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
