import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:transparent_image/transparent_image.dart';

/// A hybrid card widget for the Campus Connect screen.
///
/// It displays a background image from `imageUrl` if provided.
/// Otherwise, it falls back to a solid color design with a radial gradient.
class FeatureCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String? imageUrl; // This is now used to decide the background
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.imageUrl, // Made it an optional parameter
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // A clean way to check if we have a valid image URL to display.
    final bool hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return AspectRatio(
      aspectRatio: 16 / 8,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          clipBehavior:
              Clip.antiAlias, // Clips the image to the rounded corners
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            // The background is now conditional.
            // If there's no image, use the solid color gradient.
            // If there is an image, the image itself will be the background.
            gradient:
                hasImage
                    ? null
                    : RadialGradient(
                      colors: [Color.lerp(color, Colors.white, 0.15)!, color],
                      center: Alignment.topRight,
                      radius: 1.5,
                    ),
            // The solid color is also a good fallback for the image container
            color: color,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // --- BACKGROUND LAYER ---
              // If we have an image, display it. It will cover the container's color.
              if (hasImage)
                FadeInImage.memoryNetwork(
                  placeholder: kTransparentImage,
                  image: imageUrl!,
                  fit: BoxFit.cover,
                  // If the image fails to load, the solid color background will be visible.
                  imageErrorBuilder:
                      (context, error, stackTrace) => const SizedBox.shrink(),
                ),

              // --- GRADIENT OVERLAY (only for images) ---
              // Add a dark overlay on top of images so white text is always readable.
              if (hasImage)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                      stops: [0.5, 1.0],
                    ),
                  ),
                ),

              // --- CONTENT LAYER (Icon and Text) ---
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    // Use a slightly different background for the icon based on the card type
                    color:
                        hasImage
                            ? Colors.black.withAlpha(80)
                            : Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows:
                        hasImage
                            ? [
                              const Shadow(
                                blurRadius: 4,
                                color: Colors.black54,
                              ),
                            ]
                            : [],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
