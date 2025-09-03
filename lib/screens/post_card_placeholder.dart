import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PostCardPlaceholder extends StatelessWidget {
  const PostCardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final Color cardBackgroundColor = Colors.grey.shade900;
    final Color shimmerBaseColor = Colors.grey.shade800;
    final Color shimmerHighlightColor = Colors.grey.shade700;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Shimmer.fromColors(
        baseColor: shimmerBaseColor,
        highlightColor: shimmerHighlightColor,
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Placeholder
              Row(
                children: [
                  const CircleAvatar(radius: 20, backgroundColor: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 12,
                          width: 80,
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
              const SizedBox(height: 12),
              // Caption Placeholder
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 14,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              // Image Placeholder
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
