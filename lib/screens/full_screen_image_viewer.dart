import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag; // For the animation

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // The main image viewer
          Center(
            // The Hero widget must have the same tag as the one on the post card
            child: Hero(
              tag: heroTag,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain, // Show the whole image
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.yellow),
                  );
                },
              ),
            ),
          ),
          // The close button
          Positioned(
            top: 40,
            right: 10,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  // --- FIX APPLIED HERE ---
                  backgroundColor: Colors.black.withAlpha(128), // 0.5 opacity
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
