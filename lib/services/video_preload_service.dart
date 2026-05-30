// ===============================
// FILE NAME: video_preload_service.dart
// FILE PATH: lib/services/video_preload_service.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPreloadService {
  static final VideoPreloadService instance = VideoPreloadService._internal();
  VideoPreloadService._internal();

  final Map<String, VideoPlayerController> _controllers = {};

  /// Preloads the first few video URLs.
  Future<void> preloadVideos(List<String> urls) async {
    // 1. Remove and dispose of old controllers that are no longer in the top 3
    final keysToRemove =
        _controllers.keys.where((k) => !urls.contains(k)).toList();
    for (final k in keysToRemove) {
      _controllers[k]?.dispose();
      _controllers.remove(k);
    }

    // 2. Initialize new controllers in the background
    for (final url in urls) {
      if (!_controllers.containsKey(url)) {
        try {
          final ctrl = VideoPlayerController.networkUrl(
            Uri.parse(url),
            httpHeaders: {'User-Agent': 'EnteRITApp'},
          );

          // Add to map immediately so we don't duplicate calls
          _controllers[url] = ctrl;

          // Initialize silently
          ctrl.initialize().catchError((e) {
            debugPrint("Background preload error for $url: $e");
          });
        } catch (e) {
          debugPrint("Preload error setup: $e");
        }
      }
    }
  }

  /// Takes ownership of the controller so the FullScreenVideoPlayer can use it instantly.
  VideoPlayerController? takeController(String url) {
    return _controllers.remove(url);
  }
}
