// ===============================
// FILE NAME: story_editor_view.dart
// FILE PATH: lib/screens/stories/story_editor_view.dart
// ===============================

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import '../create_post_screen.dart'; // For PostType enum
import 'stories_connector.dart'; // Contains the updated OverlayItem model
import 'overlay_text_model.dart'; // Contains OverlayItem and OverlayType

class StoryEditorView extends StatefulWidget {
  final List<File> files;
  final PostType postType;
  final File? thumbnailFile;
  final List<double> filterMatrix; // The matrix chosen in the camera screen
  final VoidCallback onBack;
  final VoidCallback onUploadComplete;

  const StoryEditorView({
    super.key,
    required this.files,
    required this.postType,
    this.thumbnailFile,
    required this.filterMatrix,
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
                              MediaQuery.of(context).size.height / 2 - 50,
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
                              MediaQuery.of(context).size.height / 2 - 40,
                            ),
                            scale: 1.5, // Start stickers a bit larger
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
    setState(() => _isUploading = true);
    try {
      RenderRepaintBoundary boundary =
          _previewContainerKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/story_baked_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await tempFile.writeAsBytes(pngBytes);
      _finalBakedFiles.add(tempFile);

      if (_currentEditIndex < widget.files.length - 1) {
        setState(() {
          _currentEditIndex++;
          _isUploading = false;
        });
      } else {
        await _storiesService.uploadStories(_finalBakedFiles);
        if (mounted) widget.onUploadComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Action failed: $e")));
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isUploading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFFFF4B72)),
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
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. The Canvas to Bake
            RepaintBoundary(
              key: _previewContainerKey,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Base Image with Cinematic Overlay
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.matrix(widget.filterMatrix),
                      child:
                          widget.postType == PostType.video
                              ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (widget.thumbnailFile != null)
                                    Image.file(
                                      widget.thumbnailFile!,
                                      fit: BoxFit.cover,
                                    ),
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
                              : Image.file(
                                widget.files[_currentEditIndex],
                                fit: BoxFit.cover,
                              ),
                    ),
                  ),

                  // Active Overlays (Text & Stickers)
                  ..._overlays[_currentEditIndex]!.map((item) {
                    return TransformableOverlayWidget(
                      item: item,
                      onUpdate: (updatedItem) {
                        setState(() {
                          final idx = _overlays[_currentEditIndex]!.indexWhere(
                            (e) => e.id == updatedItem.id,
                          );
                          if (idx != -1)
                            _overlays[_currentEditIndex]![idx] = updatedItem;
                        });
                      },
                    );
                  }),
                ],
              ),
            ),

            // 2. Top Toolbar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                    ),
                    onPressed: widget.onBack,
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.emoji_emotions_outlined,
                          color: Colors.white,
                          size: 28,
                          shadows: [
                            Shadow(blurRadius: 10, color: Colors.black),
                          ],
                        ),
                        onPressed: _showStickerSheet,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.text_fields,
                          color: Colors.white,
                          size: 28,
                          shadows: [
                            Shadow(blurRadius: 10, color: Colors.black),
                          ],
                        ),
                        onPressed: _addTextOverlay,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. Bottom Navigation
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  widget.files.length > 1 && _currentEditIndex > 0
                      ? GestureDetector(
                        onTap:
                            () => setState(() {
                              _currentEditIndex--;
                              if (_finalBakedFiles.isNotEmpty)
                                _finalBakedFiles.removeLast();
                            }),
                        child: Container(
                          padding: const EdgeInsets.all(12),
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
                      )
                      : const SizedBox(width: 44),

                  GestureDetector(
                    onTap: _captureAndProceed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9983F3), Color(0xFFFF4B72)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4B72).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            (widget.files.length > 1 &&
                                    _currentEditIndex < widget.files.length - 1)
                                ? "Next Image"
                                : "Send to Story",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
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

// Sub-widget to cleanly handle drag, resize, rotate gestures for individual overlays
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
