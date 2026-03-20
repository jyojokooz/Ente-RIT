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
      'name': 'Auto Glow',
      'matrix': <double>[
        1.05,
        0.02,
        0.0,
        0.0,
        12.0,
        0.02,
        1.05,
        0.0,
        0.0,
        10.0,
        0.0,
        0.0,
        1.05,
        0.0,
        8.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
      ],
    },
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
      'name': 'Clarendon',
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
      'name': 'Juno',
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
      'name': 'Lark',
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
      'name': 'Gingham',
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
      'name': 'Cinematic',
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
        _selectedCameraIndex = _cameras!.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
        );
        if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;

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

  bool _isFrontCamera() {
    if (_cameras == null || _cameras!.isEmpty) return false;
    return _cameras![_selectedCameraIndex].lensDirection ==
        CameraLensDirection.front;
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _isRecording) return;
    HapticFeedback.mediumImpact();
    try {
      final XFile image = await _cameraController!.takePicture();
      _navigateToEditor(
        [File(image.path)],
        PostType.image,
        null,
        _isFrontCamera(),
      );
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
        _isFrontCamera(),
      );
    } catch (e) {
      debugPrint("Stop video error: $e");
    }
  }

  void _navigateToEditor(
    List<File> files,
    PostType type,
    File? thumbnail,
    bool isFrontCamera,
  ) {
    // USE push() INSTEAD OF pushReplacement()
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (editorContext) => StoryEditorView(
              files: files,
              postType: type,
              thumbnailFile: thumbnail,
              filterMatrix: _filters[_selectedFilterIndex]['matrix'],
              isFrontCamera: isFrontCamera,
              // Safely pop the editor context
              onBack: () => Navigator.pop(editorContext),
              onUploadComplete: () {
                // Pop the Editor
                Navigator.pop(editorContext);
                // Then Pop the Camera to return to the Home/Feed
                if (mounted) {
                  Navigator.pop(context);
                }
              },
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
                    false,
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
      body: SafeArea(
        bottom: false, // Ensures bottom bar touches the very bottom edge
        child: Column(
          children: [
            // --- 1. IDENTICAL FRAMED AREA ---
            Expanded(
              child: Padding(
                // EXACT SAME padding in both screens
                padding: const EdgeInsets.only(
                  top: 8.0,
                  left: 4.0,
                  right: 4.0,
                  bottom: 8.0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Camera Preview (Forced to cover the exact frame without stretching)
                      if (_isCameraInitialized)
                        SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width:
                                  _cameraController!
                                      .value
                                      .previewSize
                                      ?.height ??
                                  1,
                              height:
                                  _cameraController!.value.previewSize?.width ??
                                  1,
                              child: ColorFiltered(
                                colorFilter: ColorFilter.matrix(
                                  _filters[_selectedFilterIndex]['matrix'],
                                ),
                                child: CameraPreview(_cameraController!),
                              ),
                            ),
                          ),
                        )
                      else
                        const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),

                      // Subtle dark gradient at top for visibility of buttons
                      IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withOpacity(0.2),
                              ],
                              stops: const [0.0, 0.15, 0.85, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Top Controls inside the frame
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 30,
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
                                  ),
                                  onPressed: _toggleFlash,
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: const Icon(
                                    Icons.settings_outlined,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () {}, // Settings placeholder
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- 2. BOTTOM CONTROLS (FIXED EXACT HEIGHT: 160) ---
            Container(
              height: 160,
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Filter Selector (Hidden when recording)
                  if (!_isRecording)
                    SizedBox(
                      height: 55,
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
                              width: isSelected ? 50 : 36,
                              height: isSelected ? 50 : 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.matrix(
                                    _filters[index]['matrix'],
                                  ),
                                  child: Image.network(
                                    'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=200&q=80',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    const SizedBox(height: 55),

                  const SizedBox(height: 15),

                  // Capture Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Gallery Button
                        GestureDetector(
                          onTap: _openGallery,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.photo_library,
                              color: Colors.white,
                              size: 20,
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
                            width: _isRecording ? 90 : 75,
                            height: _isRecording ? 90 : 75,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: Colors.transparent,
                            ),
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: _isRecording ? 35 : 60,
                                height: _isRecording ? 35 : 60,
                                decoration: BoxDecoration(
                                  color:
                                      _isRecording ? Colors.red : Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    _isRecording ? 8 : 40,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Switch Camera Button
                        GestureDetector(
                          onTap: _switchCamera,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.flip_camera_ios,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
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
