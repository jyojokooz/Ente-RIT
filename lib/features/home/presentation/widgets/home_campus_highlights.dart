// ===============================
// FILE NAME: home_campus_highlights.dart
// FILE PATH: lib/widgets/home/home_campus_highlights.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:my_project/features/campus/presentation/highlight_video_player_screen.dart';
import 'package:my_project/core/utils/video_preload_service.dart';

class HomeCampusHighlights extends StatefulWidget {
  final bool isDark;

  const HomeCampusHighlights({super.key, required this.isDark});

  @override
  State<HomeCampusHighlights> createState() => _HomeCampusHighlightsState();
}

class _HomeCampusHighlightsState extends State<HomeCampusHighlights> {
  List<String> _currentPreloadedUrls = [];

  void _managePreloading(List<String> videoUrls) {
    // Only trigger preload if the list of URLs has changed to save bandwidth
    if (_currentPreloadedUrls.toString() != videoUrls.toString()) {
      _currentPreloadedUrls = videoUrls;
      VideoPreloadService.instance.preloadVideos(_currentPreloadedUrls);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER ROW ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Text(
            'CAMPUS HIGHLIGHTS',
            style: GoogleFonts.permanentMarker(
              fontSize: 14,
              color: textColor,
              letterSpacing: 1.2,
            ),
          ),
        ),

        // --- HORIZONTAL LIST OF VIDEOS ---
        SizedBox(
          height: 120,
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('campus_videos')
                    .orderBy('createdAt', descending: true)
                    .limit(10)
                    .snapshots(),
            builder: (context, snapshot) {
              // 1. SLEEK SHIMMER EFFECT
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Shimmer.fromColors(
                      baseColor:
                          widget.isDark
                              ? const Color(0xFF2A2A2E)
                              : Colors.grey.shade300,
                      highlightColor:
                          widget.isDark
                              ? const Color(0xFF3F3F45)
                              : Colors.grey.shade100,
                      child: Container(
                        width: 90,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "No highlights available.",
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                );
              }

              final videos = snapshot.data!.docs;

              // 2. BACKGROUND PRELOADING LOGIC
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final videoUrls =
                    videos
                        .map(
                          (doc) =>
                              (doc.data() as Map<String, dynamic>)['videoUrl']
                                  as String?,
                        )
                        .where((url) => url != null && url.isNotEmpty)
                        .cast<String>()
                        .take(5) // Preload the first 5 videos
                        .toList();

                _managePreloading(videoUrls);
              });

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
                          PageRouteBuilder(
                            transitionDuration: const Duration(
                              milliseconds: 350,
                            ),
                            reverseTransitionDuration: const Duration(
                              milliseconds: 300,
                            ),
                            pageBuilder: (
                              context,
                              animation,
                              secondaryAnimation,
                            ) {
                              return HighlightVideoPlayerScreen(
                                videoUrl: videoUrl,
                                title: title,
                                thumbnailUrl:
                                    thumbnailUrl, // Pass thumbnail for Hero
                              );
                            },
                            transitionsBuilder: (
                              context,
                              animation,
                              secondaryAnimation,
                              child,
                            ) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                          ),
                        ).then((_) {
                          // Re-preload the video immediately when the user comes back to the feed
                          VideoPreloadService.instance.preloadVideos(
                            _currentPreloadedUrls,
                          );
                        });
                      }
                    },
                    child: Container(
                      width: 90,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color:
                            widget.isDark
                                ? const Color(0xFF1C1C22)
                                : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 3. HERO ANIMATED THUMBNAIL
                            Hero(
                              tag: 'campus_video_$videoUrl',
                              child:
                                  thumbnailUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                        imageUrl: thumbnailUrl,
                                        fit: BoxFit.cover,
                                        placeholder:
                                            (
                                              context,
                                              url,
                                            ) => Shimmer.fromColors(
                                              baseColor:
                                                  widget.isDark
                                                      ? const Color(0xFF2A2A2E)
                                                      : Colors.grey.shade300,
                                              highlightColor:
                                                  widget.isDark
                                                      ? const Color(0xFF3F3F45)
                                                      : Colors.grey.shade100,
                                              child: Container(
                                                color: Colors.black,
                                              ),
                                            ),
                                        errorWidget:
                                            (context, url, error) => const Icon(
                                              Icons.error,
                                              color: Colors.grey,
                                            ),
                                      )
                                      : Container(
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
                            ),

                            // Dark Gradient Overlay for Text Readability
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
                                    stops: const [0.0, 0.7],
                                  ),
                                ),
                              ),
                            ),

                            // Content (Bottom)
                            Positioned(
                              bottom: 8,
                              left: 8,
                              right: 8,
                              child: Text(
                                title,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
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
