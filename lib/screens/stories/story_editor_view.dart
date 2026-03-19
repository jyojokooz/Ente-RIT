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

import 'stories_connector.dart';
import 'overlay_text_model.dart';

class StoryEditorView extends StatefulWidget {
  final List<File> files;
  final VoidCallback onBack;
  final VoidCallback onUploadComplete;

  const StoryEditorView({
    super.key,
    required this.files,
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

  // State for overlays per image
  late Map<int, List<OverlayText>> _overlays;
  // Temporary storage for captured baked images
  final List<File> _finalBakedFiles = [];

  @override
  void initState() {
    super.initState();
    // Initialize empty overlay lists for each file
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
                          OverlayText(
                            text: val,
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

  // Bakes the current canvas and moves to next OR uploads
  Future<void> _captureAndProceed() async {
    setState(() => _isUploading = true);

    try {
      // 1. Capture Current Canvas
      RenderRepaintBoundary boundary =
          _previewContainerKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 2. Save temporarily
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/story_baked_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await tempFile.writeAsBytes(pngBytes);
      _finalBakedFiles.add(tempFile);

      // 3. Move to next OR Upload
      if (_currentEditIndex < widget.files.length - 1) {
        setState(() {
          _currentEditIndex++;
          _isUploading = false;
        });
      } else {
        // Upload all baked files
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Text(
              "Processing...",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Stack(
        children: [
          // 1. The Canvas
          RepaintBoundary(
            key: _previewContainerKey,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(
                      widget.files[_currentEditIndex],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Active Text Overlays
                ..._overlays[_currentEditIndex]!.map((overlay) {
                  return Positioned(
                    left: overlay.offset.dx,
                    top: overlay.offset.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          overlay.offset += details.delta;
                        });
                      },
                      child: Transform.scale(
                        scale: overlay.scale,
                        child: Transform.rotate(
                          angle: overlay.rotation,
                          child: Text(
                            overlay.text,
                            style: GoogleFonts.poppins(
                              color: overlay.color,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                const Shadow(
                                  blurRadius: 4,
                                  color: Colors.black,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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
                        Icons.text_fields,
                        color: Colors.white,
                        size: 28,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                      ),
                      onPressed: _addTextOverlay,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.color_lens,
                        color: Colors.white,
                        size: 28,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                      ),
                      onPressed: () {
                        if (_overlays[_currentEditIndex]!.isNotEmpty) {
                          setState(() {
                            _overlays[_currentEditIndex]!.last.color =
                                _overlays[_currentEditIndex]!.last.color ==
                                        Colors.white
                                    ? Colors.yellow
                                    : (_overlays[_currentEditIndex]!
                                                .last
                                                .color ==
                                            Colors.yellow
                                        ? Colors.red
                                        : Colors.white);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Pagination Dots (If multiple images)
          if (widget.files.length > 1)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.files.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          _currentEditIndex == index
                              ? Colors.white
                              : Colors.white54,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
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
                            // If they go back, we need to remove the last baked file so it doesn't duplicate
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          (widget.files.length > 1 &&
                                  _currentEditIndex < widget.files.length - 1)
                              ? "Next Image"
                              : "Post Story",
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.black,
                          size: 16,
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
    );
  }
}
