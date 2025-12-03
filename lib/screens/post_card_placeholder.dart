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
    // FIX: Using very subtle colors for "Ultra Smooth" feel
    final Color baseColor = Colors.grey[200]!; 
    final Color highlightColor = Colors.grey[50]!;

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1.0),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        period: const Duration(milliseconds: 1500), // Slower animation is smoother
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
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

            // 2. MEDIA BLOCK (Large & Clean)
            Container(
              width: double.infinity,
              height: 350, // Slightly reduced height for better initial view
              color: Colors.white,
            ),

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