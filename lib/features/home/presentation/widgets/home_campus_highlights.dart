// ===============================
// FILE NAME: home_campus_highlights.dart
// FILE PATH: C:\Ente-RITEEE\Ente-RIT\lib\features\home\presentation\widgets\home_campus_highlights.dart
// ===============================

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
        // --- HEADER ROW WITH "SEE ALL" ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CAMPUS HIGHLIGHTS',
                style: GoogleFonts.permanentMarker(
                  fontSize: 14,
                  color: textColor,
                  letterSpacing: 1.2,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AllCampusHighlightsScreen(),
                    ),
                  );
                },
                child: Text(
                  'See all',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF3E8E), // Brand Pink
                  ),
                ),
              ),
            ],
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
                        .take(5)
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
                                thumbnailUrl: thumbnailUrl,
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

// ============================================================================
// NEW SCREEN: ALL CAMPUS HIGHLIGHTS GRID
// ============================================================================
class AllCampusHighlightsScreen extends StatelessWidget {
  const AllCampusHighlightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "All Highlights",
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('campus_videos')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF3E8E)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No highlights available.",
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final videos = snapshot.data!.docs;

          return GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 9 / 16, // Stories/Shorts Ratio
            ),
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
                        transitionDuration: const Duration(milliseconds: 350),
                        reverseTransitionDuration: const Duration(
                          milliseconds: 300,
                        ),
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return HighlightVideoPlayerScreen(
                            videoUrl: videoUrl,
                            title: title,
                            thumbnailUrl: thumbnailUrl,
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
                    );
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'campus_video_$videoUrl',
                        child:
                            thumbnailUrl.isNotEmpty
                                ? CachedNetworkImage(
                                  imageUrl: thumbnailUrl,
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => Container(
                                        color:
                                            isDark
                                                ? Colors.white10
                                                : Colors.black12,
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
                              stops: const [0.0, 0.5],
                            ),
                          ),
                        ),
                      ),
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(
                          Icons.play_circle_outline_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            height: 1.2,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
