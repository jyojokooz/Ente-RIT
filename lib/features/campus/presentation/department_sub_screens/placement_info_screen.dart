// ===============================
// FILE NAME: placement_info_screen.dart
// FILE PATH: lib/features/campus/presentation/department_sub_screens/placement_info_screen.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:my_project/features/campus/data/rit_scraper_service.dart';

class PlacementInfoScreen extends StatelessWidget {
  final String url;
  const PlacementInfoScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final textColor = isDark ? Colors.white : Colors.black87;

    final RitScraperService scraper = RitScraperService();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Placement Highlights",
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
      body: FutureBuilder<List<String>>(
        future: scraper.getPlacementImages(url),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF43E97B)),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No placement images found.",
                style: GoogleFonts.poppins(color: textColor),
              ),
            );
          }
          final images = snapshot.data!;
          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            itemCount: images.length,
            separatorBuilder: (c, i) => const SizedBox(height: 24),
            itemBuilder:
                (context, index) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: CachedNetworkImage(
                      imageUrl: images[index],
                      placeholder:
                          (c, u) => Container(
                            height: 200,
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
          );
        },
      ),
    );
  }
}
