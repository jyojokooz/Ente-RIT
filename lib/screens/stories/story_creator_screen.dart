// ===============================
// FILE NAME: story_creator_screen.dart
// FILE PATH: lib/screens/stories/story_creator_screen.dart
// ===============================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
// FIX 1: Added 'as vt' to resolve the ImageFormat name collision
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:path_provider/path_provider.dart';

import '../create_post_screen.dart'; // For PostType enum
import 'story_gallery_view.dart';
import 'story_editor_view.dart';

class StoryCreatorScreen extends StatefulWidget {
  const StoryCreatorScreen({super.key});

  @override
  State<StoryCreatorScreen> createState() => _StoryCreatorScreenState();
}

class _StoryCreatorScreenState extends State<StoryCreatorScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  FlashMode _flashMode = FlashMode.off;

  // Live Filters matching your editor
  int _selectedFilterIndex = 0;
  final List<Map<String, dynamic>> _filters = [
    {
      'name': 'Normal',
      'color': Colors.transparent,
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
    },
    {
      'name': 'B&W',
      'color': Colors.grey,
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
    },
    {
      'name': 'Sepia',
      'color': Colors.orangeAccent,
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
    },
    {
      'name': 'Cool',
      'color': Colors.blueAccent,
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
    },
    {
      'name': 'Fade',
      'color': Colors.brown,
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
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _setCamera(_cameras![_selectedCameraIndex]);
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  Future<void> _setCamera(CameraDescription cameraDescription) async {
    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: true,
    );

    try {
      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(_flashMode);
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint("Set camera error: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // FIX 2: Added curly braces for all if statements
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_cameras != null) {
        _setCamera(_cameras![_selectedCameraIndex]);
      }
    }
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) {
      return;
    }
    setState(() => _isCameraInitialized = false);
    _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;
    _setCamera(_cameras![_selectedCameraIndex]);
  }

  void _toggleFlash() {
    setState(() {
      _flashMode =
          _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
      _cameraController?.setFlashMode(_flashMode);
    });
  }

  // --- CAPTURE LOGIC ---
  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _isRecording) {
      return;
    }
    try {
      final XFile image = await _cameraController!.takePicture();
      _navigateToEditor([File(image.path)], PostType.image, null);
    } catch (e) {
      debugPrint("Take picture error: $e");
    }
  }

  Future<void> _startVideoRecording() async {
    if (!_isCameraInitialized || _isRecording) {
      return;
    }
    try {
      await _cameraController!.startVideoRecording();
      setState(() => _isRecording = true);
    } catch (e) {
      debugPrint("Start video error: $e");
    }
  }

  Future<void> _stopVideoRecording() async {
    if (!_isCameraInitialized || !_isRecording) {
      return;
    }
    try {
      final XFile video = await _cameraController!.stopVideoRecording();
      setState(() => _isRecording = false);

      final tempDir = await getTemporaryDirectory();

      // FIX 1: Using the vt prefix for the video_thumbnail plugin
      final thumbPath = await vt.VideoThumbnail.thumbnailFile(
        video: video.path,
        thumbnailPath: tempDir.path,
        imageFormat: vt.ImageFormat.JPEG, // Used the prefix here
        quality: 75,
      );

      _navigateToEditor(
        [File(video.path)],
        PostType.video,
        thumbPath != null ? File(thumbPath) : null,
      );
    } catch (e) {
      debugPrint("Stop video error: $e");
    }
  }

  // --- NAVIGATION ---
  void _navigateToEditor(List<File> files, PostType type, File? thumbnail) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => StoryEditorView(
              files: files,
              onBack: () => Navigator.pop(context),
              onUploadComplete: () => Navigator.pop(context),
            ),
      ),
    );
  }

  void _openGallery() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: StoryGalleryView(
                onFilesSelected: (files) {
                  Navigator.pop(ctx);
                  final isVideo = files.first.path.toLowerCase().endsWith(
                    '.mp4',
                  );
                  _navigateToEditor(
                    files,
                    isVideo ? PostType.video : PostType.image,
                    null,
                  );
                },
                onCancel: () => Navigator.pop(ctx),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! < -500) {
            _openGallery();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. LIVE CAMERA PREVIEW WITH LIVE COLOR FILTERS
            if (_isCameraInitialized)
              ColorFiltered(
                colorFilter: ColorFilter.matrix(
                  _filters[_selectedFilterIndex]['matrix'],
                ),
                child: Center(child: CameraPreview(_cameraController!)),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // 2. TOP CONTROLS
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _flashMode == FlashMode.torch
                              ? Icons.flash_on
                              : Icons.flash_off,
                          color: Colors.white,
                          size: 28,
                          shadows: const [
                            Shadow(blurRadius: 4, color: Colors.black),
                          ],
                        ),
                        onPressed: _toggleFlash,
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(
                          Icons.flip_camera_ios_rounded,
                          color: Colors.white,
                          size: 28,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                        ),
                        onPressed: _switchCamera,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. SWIPE UP HINT
            Positioned(
              bottom: 180,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Colors.white70,
                    size: 30,
                    shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                  ),
                  Text(
                    "Swipe up for Gallery",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      shadows: [
                        const Shadow(blurRadius: 2, color: Colors.black),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 4. LIVE FILTER WHEEL & BOTTOM CONTROLS
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Filter Carousel (Snapchat style)
                  SizedBox(
                    height: 80,
                    child: PageView.builder(
                      controller: PageController(
                        viewportFraction: 0.2,
                        initialPage: _selectedFilterIndex,
                      ),
                      onPageChanged:
                          (index) =>
                              setState(() => _selectedFilterIndex = index),
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedFilterIndex == index;
                        return Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isSelected ? 65 : 45,
                            height: isSelected ? 65 : 45,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: isSelected ? 3 : 1,
                              ),
                              color: _filters[index]['color'].withOpacity(0.5),
                            ),
                            child:
                                isSelected
                                    ? null
                                    : Center(
                                      child: Text(
                                        _filters[index]['name'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 9,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Capture Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Gallery Button
                        GestureDetector(
                          onTap: _openGallery,
                          child: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.photo_library_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),

                        // Capture Button (Tap for Photo, Hold for Video)
                        GestureDetector(
                          onTap: _takePicture,
                          onLongPress: _startVideoRecording,
                          onLongPressUp: _stopVideoRecording,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _isRecording ? 90 : 80,
                            height: _isRecording ? 90 : 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 5),
                              color:
                                  _isRecording
                                      ? Colors.red
                                      : Colors.transparent,
                            ),
                            child: Center(
                              child: Container(
                                width: _isRecording ? 30 : 65,
                                height: _isRecording ? 30 : 65,
                                decoration: BoxDecoration(
                                  color:
                                      _isRecording
                                          ? Colors.white
                                          : Colors.white70,
                                  borderRadius: BorderRadius.circular(
                                    _isRecording ? 8 : 40,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Empty space to balance the row
                        const SizedBox(width: 45),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
