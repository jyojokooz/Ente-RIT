// ===============================
// FILE NAME: highlight_video_player_screen.dart
// FILE PATH: lib/screens/highlight_video_player_screen.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_project/core/utils/video_preload_service.dart';

class HighlightVideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String thumbnailUrl;

  const HighlightVideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.thumbnailUrl,
  });

  @override
  State<HighlightVideoPlayerScreen> createState() =>
      _HighlightVideoPlayerScreenState();
}

class _HighlightVideoPlayerScreenState
    extends State<HighlightVideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  // --- NO LAG PRELOAD LOGIC ---
  Future<void> _initializeVideo() async {
    try {
      // 1. Instantly take the preloaded controller if it exists
      var ctrl = VideoPreloadService.instance.takeController(widget.videoUrl);

      // 2. If it wasn't preloaded, initialize it manually
      if (ctrl == null) {
        ctrl = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
          httpHeaders: {'User-Agent': 'EnteRITApp'},
        );
        await ctrl.initialize();
      }

      if (!mounted) {
        ctrl.dispose();
        return;
      }

      if (ctrl.value.hasError) {
        throw Exception(ctrl.value.errorDescription);
      }

      ctrl.setLooping(true);
      ctrl.play();
      ctrl.addListener(() {
        if (mounted) setState(() {});
      });

      setState(() {
        _controller = ctrl;
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint("Video Player Initialization Error: $e");
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. HERO WRAPPED VIDEO PLAYER
          Center(
            child:
                _hasError
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white54,
                          size: 50,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Failed to load video.",
                          style: GoogleFonts.poppins(color: Colors.white54),
                        ),
                      ],
                    )
                    : Hero(
                      tag: 'campus_video_${widget.videoUrl}',
                      // If video is ready, show it. Otherwise, show the expanded Thumbnail smoothly
                      child:
                          _isInitialized && _controller != null
                              ? AspectRatio(
                                aspectRatio: _controller!.value.aspectRatio,
                                child: VideoPlayer(_controller!),
                              )
                              : AspectRatio(
                                aspectRatio:
                                    16 /
                                    9, // Fallback ratio for smooth transition
                                child: CachedNetworkImage(
                                  imageUrl: widget.thumbnailUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                    ),
          ),

          // 2. Play/Pause Overlay
          if (_isInitialized && _controller != null)
            GestureDetector(
              onTap: () {
                setState(() {
                  _controller!.value.isPlaying
                      ? _controller!.pause()
                      : _controller!.play();
                });
              },
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child:
                      !_controller!.value.isPlaying
                          ? Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 50,
                            ),
                          )
                          : const SizedBox.shrink(),
                ),
              ),
            ),

          // 3. Top Bar (Close button)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. Bottom Info & Progress Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  if (_isInitialized && _controller != null)
                    VideoProgressIndicator(
                      _controller!,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Color(0xFFFF3E8E),
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.white10,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
