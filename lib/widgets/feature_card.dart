import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:transparent_image/transparent_image.dart';

/// A reusable card widget for the Classify/Campus Connect screen.
///
/// Displays a background image with a gradient overlay if an `imageUrl` is provided.
/// Falls back to a solid color card with a centered icon and text if no
/// `imageUrl` is available or if the image fails to load.
class FeatureCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? imageUrl;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.label,
    required this.icon,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // A flag to easily check if a valid image URL was provided.
    final bool hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior:
            Clip.antiAlias, // Ensures the image is clipped to the card's rounded corners
        color: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Background Image (only if it exists)
            if (hasImage)
              FadeInImage.memoryNetwork(
                placeholder:
                    kTransparentImage, // Shows a transparent placeholder while loading
                image: imageUrl!,
                fit: BoxFit.cover,
                // This is the fallback for when the image URL is invalid or network fails.
                // It renders the default icon-and-text view instead of an error icon.
                imageErrorBuilder: (context, error, stackTrace) {
                  return _buildIconAndTextContent(hasImage: false);
                },
              ),

            // Layer 2: Gradient Overlay (only if there's an image to darken)
            if (hasImage)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black54,
                      Colors.black87,
                    ],
                    stops: [
                      0.4,
                      0.7,
                      1.0,
                    ], // Controls where the gradient starts and ends
                  ),
                ),
              ),

            // Layer 3: The actual content (Icon and Text)
            _buildIconAndTextContent(hasImage: hasImage),
          ],
        ),
      ),
    );
  }

  /// A helper widget to build the card's content.
  ///
  /// The layout changes depending on whether a background image is present.
  Widget _buildIconAndTextContent({required bool hasImage}) {
    // If there is an image, align content to the bottom-left.
    // If not, center the content.
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment:
            hasImage ? MainAxisAlignment.end : MainAxisAlignment.center,
        crossAxisAlignment:
            hasImage ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          // Only show the large icon if there is NO background image.
          if (!hasImage) ...[
            Icon(icon, color: Colors.yellow.shade700, size: 40),
            const SizedBox(height: 12),
          ],
          Text(
            label,
            textAlign: hasImage ? TextAlign.start : TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              // Add a shadow to the text only if it's on top of an image
              // to improve readability.
              shadows:
                  hasImage
                      ? [
                        const Shadow(
                          blurRadius: 8.0,
                          color: Colors.black,
                          offset: Offset(1.5, 1.5),
                        ),
                      ]
                      : null,
            ),
          ),
        ],
      ),
    );
  }
}
