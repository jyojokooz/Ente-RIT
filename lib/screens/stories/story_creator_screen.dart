// ===============================
// FILE NAME: story_creator_screen.dart
// FILE PATH: lib/screens/stories/story_creator_screen.dart
// ===============================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
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
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  FlashMode _flashMode = FlashMode.off;

  late PageController _filterPageController;
  int _selectedFilterIndex = 0;

  // Professional Color Matrices
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
    },
    {
      'name': 'Clarendon', // Bright cool tone, boosted shadows
      'matrix': <double>[
        1.2,
        0,
        0,
        0,
        10,
        0,
        1.2,
        0,
        0,
        20,
        0,
        0,
        1.3,
        0,
        30,
        0,
        0,
        0,
        1,
        0,
      ],
    },
    {
      'name': 'Juno', // Warm vibrant
      'matrix': <double>[
        1.2,
        0,
        0,
        0,
        20,
        0,
        1.1,
        0,
        0,
        10,
        0,
        0,
        0.9,
        0,
        -10,
        0,
        0,
        0,
        1,
        0,
      ],
    },
    {
      'name': 'Lark', // Soft bright, desaturated reds
      'matrix': <double>[
        0.9,
        0,
        0,
        0,
        10,
        0,
        1.1,
        0,
        0,
        20,
        0,
        0,
        1.1,
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
      'name': 'Gingham', // Faded vintage
      'matrix': <double>[
        1.1,
        0,
        0,
        0,
        30,
        0,
        1.0,
        0,
        0,
        20,
        0,
        0,
        0.9,
        0,
        10,
        0,
        0,
        0,
        1,
        0,
      ],
    },
    {
      'name': 'Moon', // B&W High Contrast
      'matrix': <double>[
        0.33,
        0.59,
        0.11,
        0,
        0,
        0.33,
        0.59,
        0.11,
        0,
        0,
        0.33,
        0.59,
        0.11,
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
      'name': 'Cinematic', // Teal & Orange Look
      'matrix': <double>[
        1.2,
        0.1,
        0,
        0,
        20,
        0,
        1.0,
        0.1,
        0,
        0,
        0,
        0.1,
        1.2,
        0,
        -20,
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
    _filterPageController = PageController(viewportFraction: 0.22);
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
      imageFormatGroup: ImageFormatGroup.jpeg,
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
    _filterPageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_cameras != null) _setCamera(_cameras![_selectedCameraIndex]);
    }
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    setState(() => _isCameraInitialized = false);
    _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;
    _setCamera(_cameras![_selectedCameraIndex]);
    HapticFeedback.lightImpact();
  }

  void _toggleFlash() {
    setState(() {
      _flashMode =
          _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
      _cameraController?.setFlashMode(_flashMode);
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _isRecording) return;
    HapticFeedback.mediumImpact();
    try {
      final XFile image = await _cameraController!.takePicture();
      _navigateToEditor([File(image.path)], PostType.image, null);
    } catch (e) {
      debugPrint("Take picture error: $e");
    }
  }

  Future<void> _startVideoRecording() async {
    if (!_isCameraInitialized || _isRecording) return;
    HapticFeedback.heavyImpact();
    try {
      await _cameraController!.startVideoRecording();
      setState(() => _isRecording = true);
    } catch (e) {
      debugPrint("Start video error: $e");
    }
  }

  Future<void> _stopVideoRecording() async {
    if (!_isCameraInitialized || !_isRecording) return;
    HapticFeedback.mediumImpact();
    try {
      final XFile video = await _cameraController!.stopVideoRecording();
      setState(() => _isRecording = false);
      final tempDir = await getTemporaryDirectory();
      final thumbPath = await vt.VideoThumbnail.thumbnailFile(
        video: video.path,
        thumbnailPath: tempDir.path,
        imageFormat: vt.ImageFormat.JPEG,
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

  void _navigateToEditor(List<File> files, PostType type, File? thumbnail) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => StoryEditorView(
              files: files,
              postType: type,
              thumbnailFile: thumbnail,
              filterMatrix:
                  _filters[_selectedFilterIndex]['matrix'], // Pass active filter
              onBack: () => Navigator.pop(context),
              onUploadComplete: () => Navigator.pop(context),
            ),
      ),
    );
  }

  void _openGallery() {
    HapticFeedback.lightImpact();
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
          if (details.primaryVelocity! < -500)
            _openGallery(); // Swipe up for gallery
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // --- 1. LIVE CAMERA & FILTERS ---
            if (_isCameraInitialized)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(
                    _filters[_selectedFilterIndex]['matrix'],
                  ),
                  child: Transform.scale(
                    scale: 1.0,
                    child: Center(child: CameraPreview(_cameraController!)),
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // --- 2. CINEMATIC OVERLAYS ---
            // Subtle Vignette
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                    radius: 1.2,
                  ),
                ),
              ),
            ),
            // Light Leak (Slight warm glow from top right)
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      const Color(0xFFFF9A44).withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // --- 3. TOP CONTROLS ---
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

            // --- 4. BOTTOM CONTROLS ---
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(top: 60, bottom: 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // FILTER SELECTOR
                    SizedBox(
                      height: 80,
                      child: PageView.builder(
                        controller: _filterPageController,
                        onPageChanged: (index) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedFilterIndex = index);
                        },
                        itemCount: _filters.length,
                        itemBuilder: (context, index) {
                          final isSelected = _selectedFilterIndex == index;
                          return Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              width: isSelected ? 75 : 55,
                              height: isSelected ? 75 : 55,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.white54,
                                  width: isSelected ? 4 : 2,
                                ),
                                boxShadow:
                                    isSelected
                                        ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 10,
                                          ),
                                        ]
                                        : [],
                              ),
                              child: ClipOval(
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.matrix(
                                    _filters[index]['matrix'],
                                  ),
                                  child: Image.network(
                                    'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=200&q=80', // Generic model placeholder
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    // ACTIVE FILTER NAME
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: 1.0,
                      child: Text(
                        _filters[_selectedFilterIndex]['name'],
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          shadows: [
                            const Shadow(blurRadius: 4, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // CAPTURE ROW
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Gallery Button
                          GestureDetector(
                            onTap: _openGallery,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white70,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.black45,
                              ),
                              child: const Icon(
                                Icons.photo_library_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          // Capture Button
                          GestureDetector(
                            onTap: _takePicture,
                            onLongPress: _startVideoRecording,
                            onLongPressUp: _stopVideoRecording,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: _isRecording ? 100 : 85,
                              height: _isRecording ? 100 : 85,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 5,
                                ),
                                color:
                                    _isRecording
                                        ? Colors.redAccent.withOpacity(0.5)
                                        : Colors.transparent,
                              ),
                              child: Center(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: _isRecording ? 35 : 70,
                                  height: _isRecording ? 35 : 70,
                                  decoration: BoxDecoration(
                                    color:
                                        _isRecording
                                            ? Colors.red
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      _isRecording ? 10 : 40,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 48), // Balancer
                        ],
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
