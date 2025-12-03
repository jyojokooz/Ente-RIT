// ===============================
// FILE NAME: post_card_placeholder.dart
// FILE PATH: lib/screens/post_card_placeholder.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PostCardPlaceholder extends StatelessWidget {
  const PostCardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    // FIX: Darkened the grey slightly so the shimmer is actually visible on white screens
    final Color baseColor = Colors.grey[300]!;
    final Color highlightColor = Colors.grey[100]!;

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1.0),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        period: const Duration(milliseconds: 1500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 10.0,
              ),
              child: Row(
                children: [
                  // Avatar Circle
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color:
                          Colors
                              .white, // IMPORTANT: Must be a solid color for shimmer to work
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Username Line
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),

            // 2. MEDIA BLOCK
            Container(width: double.infinity, height: 350, color: Colors.white),

            // 3. TEXT LINES
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 250,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
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
