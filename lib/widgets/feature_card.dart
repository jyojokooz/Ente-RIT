// lib/widgets/feature_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FeatureCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String? imageUrl; // The new property to accept the image URL
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if we have a valid image URL to display.
    final bool hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      clipBehavior:
          Clip.antiAlias, // Ensures the container respects the card's rounded corners
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            // --- CORE LOGIC: Display image or color background ---
            color:
                hasImage
                    ? Colors.grey.shade800
                    : color, // Fallback color while image loads
            image:
                hasImage
                    ? DecorationImage(
                      image: CachedNetworkImageProvider(imageUrl!),
                      fit: BoxFit.cover,
                      // Add a color filter to create a dark overlay for better text readability.
                      colorFilter: ColorFilter.mode(
                        // ignore: deprecated_member_use
                        Colors.black.withOpacity(0.5),
                        BlendMode.darken,
                      ),
                    )
                    : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.end, // Align content to the bottom
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align content to the left
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      const Shadow(
                        blurRadius: 4.0,
                        color: Colors.black54,
                        offset: Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
