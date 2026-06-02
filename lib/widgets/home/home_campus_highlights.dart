// ===============================
// FILE NAME: home_campus_highlights.dart
// FILE PATH: lib/widgets/home/home_campus_highlights.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../screens/highlight_video_player_screen.dart'; // Import the new video player

class HomeCampusHighlights extends StatelessWidget {
  final bool isDark;

  const HomeCampusHighlights({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER ROW ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Text(
            'CAMPUS HIGHLIGHTS',
            style: GoogleFonts.permanentMarker(
              fontSize: 16,
              color: textColor,
              letterSpacing: 1.2,
            ),
          ),
        ),

        // --- HORIZONTAL LIST OF VIDEOS ---
        SizedBox(
          height: 180, // Taller height for video thumbnails
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('campus_videos') // Connects to new collection
                    .orderBy('createdAt', descending: true)
                    .limit(10) // Get top 10 latest videos
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF9983F3)),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "No highlights available.",
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                );
              }

              final videos = snapshot.data!.docs;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final data = videos[index].data() as Map<String, dynamic>;
                  final title = data['title'] ?? 'Video';
                  final thumbnailUrl = data['thumbnailUrl'] ?? '';
                  final videoUrl = data['videoUrl'] ?? '';

                  return GestureDetector(
                    onTap: () {
                      if (videoUrl.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => HighlightVideoPlayerScreen(
                                  videoUrl: videoUrl,
                                  title: title,
                                ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 130, // Slightly wider for video format
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? const Color(0xFF1C1C22)
                                : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 1. Thumbnail Image
                            if (thumbnailUrl.isNotEmpty)
                              CachedNetworkImage(
                                imageUrl: thumbnailUrl,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) =>
                                        Container(color: Colors.black12),
                                errorWidget:
                                    (context, url, error) => const Icon(
                                      Icons.error,
                                      color: Colors.grey,
                                    ),
                              )
                            else
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF3B2667),
                                      Color(0xFFBC78EC),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),

                            // 2. Play Icon Overlay (Center)
                            Container(
                              color: Colors.black.withOpacity(0.2), // Light dim
                              child: const Center(
                                child: Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),

                            // 3. Dark Gradient Overlay for Text Readability
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.center,
                                    colors: [
                                      Colors.black.withOpacity(0.9),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.6],
                                  ),
                                ),
                              ),
                            ),

                            // 4. Content (Bottom)
                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: Text(
                                title,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
