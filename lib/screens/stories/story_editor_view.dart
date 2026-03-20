// ===============================
// FILE NAME: story_editor_view.dart
// FILE PATH: lib/screens/stories/story_editor_view.dart
// ===============================

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import '../create_post_screen.dart'; // For PostType enum
import 'stories_connector.dart';
import 'overlay_text_model.dart';

class StoryEditorView extends StatefulWidget {
  final List<File> files;
  final PostType postType;
  final File? thumbnailFile;
  final List<double> filterMatrix;
  final bool isFrontCamera;
  final VoidCallback onBack;
  final VoidCallback onUploadComplete;

  const StoryEditorView({
    super.key,
    required this.files,
    required this.postType,
    this.thumbnailFile,
    required this.filterMatrix,
    this.isFrontCamera = false,
    required this.onBack,
    required this.onUploadComplete,
  });

  @override
  State<StoryEditorView> createState() => _StoryEditorViewState();
}

class _StoryEditorViewState extends State<StoryEditorView> {
  final GlobalKey _previewContainerKey = GlobalKey();
  final StoriesService _storiesService = StoriesService();

  int _currentEditIndex = 0;
  bool _isUploading = false;

  late Map<int, List<OverlayItem>> _overlays;
  final List<File> _finalBakedFiles = [];

  final List<String> _stickerEmojis = [
    '🔥',
    '💯',
    '😂',
    '❤️',
    '😍',
    '✨',
    '🎉',
    '🙌',
    '😎',
    '🎓',
    '📚',
    '🚀',
    '💡',
    '🍕',
    '☕',
  ];

  @override
  void initState() {
    super.initState();
    _overlays = {for (int i = 0; i < widget.files.length; i++) i: []};
  }

  void _addTextOverlay() {
    TextEditingController textController = TextEditingController();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder:
          (context) => Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: Colors.transparent,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: textController,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Type something...",
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      setState(() {
                        _overlays[_currentEditIndex]!.add(
                          OverlayItem(
                            id: DateTime.now().toString(),
                            type: OverlayType.text,
                            content: val,
                            offset: Offset(
                              MediaQuery.of(context).size.width / 2 - 50,
                              MediaQuery.of(context).size.height /
                                  3, // placed higher up
                            ),
                          ),
                        );
                      });
                    }
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
    );
  }

  void _showStickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: _stickerEmojis.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _overlays[_currentEditIndex]!.add(
                          OverlayItem(
                            id: DateTime.now().toString(),
                            type: OverlayType.sticker,
                            content: _stickerEmojis[index],
                            offset: Offset(
                              MediaQuery.of(context).size.width / 2 - 40,
                              MediaQuery.of(context).size.height / 3,
                            ),
                            scale: 1.5,
                          ),
                        );
                      });
                      Navigator.pop(context);
                    },
                    child: Center(
                      child: Text(
                        _stickerEmojis[index],
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
    );
  }

  Future<void> _captureAndProceed() async {
    if (_isUploading) return;

    setState(() => _isUploading = true);

    try {
      // Small delay to ensure any active keyboard/UI shifts are settled
      await Future.delayed(const Duration(milliseconds: 150));

      // 1. Find the boundary to screenshot
      RenderRepaintBoundary? boundary =
          _previewContainerKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception("Could not find the image canvas.");
      }

      // 2. Take the screenshot (Reduced pixelRatio to 2.0 to prevent memory crashes)
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception("Failed to convert image to bytes.");
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/story_baked_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await tempFile.writeAsBytes(pngBytes);

      _finalBakedFiles.add(tempFile);

      if (!mounted) return;

      // 3. Move to next image OR upload
      if (_currentEditIndex < widget.files.length - 1) {
        setState(() {
          _currentEditIndex++;
          _isUploading = false;
        });
      } else {
        await _storiesService.uploadStories(_finalBakedFiles);

        if (!mounted) return;
        widget.onUploadComplete();
      }
    } catch (e) {
      debugPrint("STORY UPLOAD ERROR: $e"); // Prints exact error to console
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to process image: ${e.toString().split(':').first}",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isUploading = false);
      }
    }
  }

  // UI components for top right tool buttons
  Widget _buildToolButton(IconData icon, VoidCallback onTap, {String? text}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child:
            text != null
                ? Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
                : Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Prepare Media Background Layer
    Widget
    mediaLayer =
        widget.postType == PostType.video
            ? Stack(
              fit: StackFit.expand,
              children: [
                if (widget.thumbnailFile != null)
                  Image.file(widget.thumbnailFile!, fit: BoxFit.cover),
                Container(color: Colors.black54),
                const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
              ],
            )
            // Image spans the exact dimensions of the expanded frame identically to the camera
            : SizedBox.expand(
              child: Image.file(
                widget.files[_currentEditIndex],
                fit: BoxFit.cover,
              ),
            );

    // FLIP MIRROR HACK: Un-mirror front camera photos
    if (widget.isFrontCamera) {
      mediaLayer = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(math.pi),
        child: mediaLayer,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
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
                          // Base Image wrapped in RepaintBoundary (We only screenshot the inner image)
                          RepaintBoundary(
                            key: _previewContainerKey,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ColorFiltered(
                                  colorFilter: ColorFilter.matrix(
                                    widget.filterMatrix,
                                  ),
                                  child: mediaLayer,
                                ),
                                // Active Overlays (Text & Stickers)
                                ..._overlays[_currentEditIndex]!.map((item) {
                                  return TransformableOverlayWidget(
                                    item: item,
                                    onUpdate: (updatedItem) {
                                      setState(() {
                                        final idx =
                                            _overlays[_currentEditIndex]!
                                                .indexWhere(
                                                  (e) => e.id == updatedItem.id,
                                                );
                                        if (idx != -1) {
                                          _overlays[_currentEditIndex]![idx] =
                                              updatedItem;
                                        }
                                      });
                                    },
                                  );
                                }),
                              ],
                            ),
                          ),

                          // Top Controls (Overlayed over the frame)
                          if (!_isUploading) ...[
                            // Top subtle dark gradient
                            IgnorePointer(
                              child: Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.3),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Back Button
                            Positioned(
                              top: 16,
                              left: 16,
                              child: GestureDetector(
                                onTap: widget.onBack,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),

                            // Right Tool Column (Aa, Sticker, etc.)
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Column(
                                children: [
                                  _buildToolButton(
                                    Icons.text_fields,
                                    _addTextOverlay,
                                    text: "Aa",
                                  ),
                                  _buildToolButton(
                                    Icons.emoji_emotions_outlined,
                                    _showStickerSheet,
                                  ),
                                  _buildToolButton(
                                    Icons.music_note_outlined,
                                    () {},
                                  ),
                                  _buildToolButton(Icons.auto_fix_high, () {}),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // --- 2. BOTTOM CONTROLS (FIXED EXACT HEIGHT: 160) ---
                Container(
                  height: 160,
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child:
                      !_isUploading
                          ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // "Your story" Pill Button
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _captureAndProceed,
                                      child: Container(
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade900,
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const CircleAvatar(
                                              radius: 12,
                                              backgroundColor: Colors.grey,
                                              backgroundImage: AssetImage(
                                                'assets/default_avatar.png',
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Your story",
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // "Close Friends" Pill Button
                                  Expanded(
                                    child: Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade900,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.star,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Close Friends",
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Next Arrow Button
                                  GestureDetector(
                                    onTap: _captureAndProceed,
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: const BoxDecoration(
                                        color: Colors.blueAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                          : const SizedBox.shrink(),
                ),
              ],
            ),

            // LOADING OVERLAY (Drawn ON TOP while uploading)
            if (_isUploading)
              Container(
                color: Colors.black87,
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 20),
                      Text(
                        "Publishing Story...",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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

// Sub-widget for gestures (Remains identical)
class TransformableOverlayWidget extends StatefulWidget {
  final OverlayItem item;
  final ValueChanged<OverlayItem> onUpdate;

  const TransformableOverlayWidget({
    super.key,
    required this.item,
    required this.onUpdate,
  });

  @override
  State<TransformableOverlayWidget> createState() =>
      _TransformableOverlayWidgetState();
}

class _TransformableOverlayWidgetState
    extends State<TransformableOverlayWidget> {
  double _initialScale = 1.0;
  double _initialRotation = 0.0;
  Offset _initialOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.item.offset.dx,
      top: widget.item.offset.dy,
      child: GestureDetector(
        onScaleStart: (details) {
          _initialScale = widget.item.scale;
          _initialRotation = widget.item.rotation;
          _initialOffset = widget.item.offset;
        },
        onScaleUpdate: (details) {
          setState(() {
            widget.item.offset = _initialOffset + details.focalPointDelta;
            widget.item.scale = (_initialScale * details.scale).clamp(0.5, 4.0);
            widget.item.rotation = _initialRotation + details.rotation;
          });
          widget.onUpdate(widget.item);
        },
        child: Transform.scale(
          scale: widget.item.scale,
          child: Transform.rotate(
            angle: widget.item.rotation,
            child:
                widget.item.type == OverlayType.text
                    ? Text(
                      widget.item.content,
                      style: GoogleFonts.poppins(
                        color: widget.item.color,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          const Shadow(
                            blurRadius: 10,
                            color: Colors.black87,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    )
                    : Text(
                      widget.item.content,
                      style: const TextStyle(
                        fontSize: 60,
                        shadows: [
                          Shadow(blurRadius: 10, color: Colors.black87),
                        ],
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}
