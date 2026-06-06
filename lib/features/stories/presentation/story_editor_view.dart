// ===============================
// FILE NAME: story_editor_view.dart
// FILE PATH: lib/features/stories/presentation/story_editor_view.dart
// ===============================

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import 'package:my_project/features/posts/presentation/create_post_screen.dart'; // For PostType enum
import 'package:my_project/features/stories/presentation/stories_connector.dart';

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
                              MediaQuery.of(context).size.width / 2 - 80,
                              MediaQuery.of(context).size.height / 3,
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
      await Future.delayed(const Duration(milliseconds: 150));

      RenderRepaintBoundary? boundary =
          _previewContainerKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception("Could not find the image canvas.");
      }

      // FIX: Lowered pixelRatio to 1.5 to prevent memory crashes / ANRs on mid-range Androids
      ui.Image image = await boundary.toImage(pixelRatio: 1.5);
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
      debugPrint("STORY UPLOAD ERROR: $e");
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

  Widget _buildToolButton(IconData icon, VoidCallback onTap, {String? text}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child:
            text != null
                ? Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
                : Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget mediaLayer =
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
            : SizedBox.expand(
              child: Image.file(
                widget.files[_currentEditIndex],
                fit: BoxFit.cover,
              ),
            );

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
                Expanded(
                  child: Padding(
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
                                // Active Overlays
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

                          if (!_isUploading) ...[
                            IgnorePointer(
                              child: Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.4),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
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
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Column(
                                children: [
                                  // REMOVED: Non-functioning Magic Wand and Music Buttons
                                  _buildToolButton(
                                    Icons.text_fields,
                                    _addTextOverlay,
                                    text: "Aa",
                                  ),
                                  _buildToolButton(
                                    Icons.emoji_emotions_outlined,
                                    _showStickerSheet,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                Container(
                  height: 120,
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child:
                      !_isUploading
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Cleaned up Bottom Buttons (Removed fake "Close Friends")
                              Expanded(
                                child: GestureDetector(
                                  onTap: _captureAndProceed,
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.grey,
                                          backgroundImage: AssetImage(
                                            'assets/default_avatar.png',
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          "Share to Your Story",
                                          style: GoogleFonts.poppins(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: _captureAndProceed,
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: const BoxDecoration(
                                    color: Colors.blueAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          )
                          : const SizedBox.shrink(),
                ),
              ],
            ),

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

// --- FIX: DRAGGING AND SCALING MATHEMATICS ---
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

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.item.offset.dx,
      top: widget.item.offset.dy,
      child: GestureDetector(
        onScaleStart: (details) {
          _initialScale = widget.item.scale;
          _initialRotation = widget.item.rotation;
        },
        onScaleUpdate: (details) {
          setState(() {
            // FIX: We must add the delta to the current offset, NOT the initial offset
            widget.item.offset += details.focalPointDelta;
            widget.item.scale = (_initialScale * details.scale).clamp(0.5, 5.0);
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
