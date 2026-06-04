// ===============================
// FILE NAME: hod_info_screen.dart
// FILE PATH: lib/features/campus/presentation/department_sub_screens/hod_info_screen.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:my_project/features/campus/data/rit_scraper_service.dart';
// --- IMPORT THE MEDIA VIEWER CONNECTOR ---
import 'package:my_project/core/widgets/media_viewers/media_viewers_connector.dart';

class HodInfoScreen extends StatelessWidget {
  final String url;
  const HodInfoScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    final RitScraperService scraper = RitScraperService();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "HOD's Desk",
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
      body: FutureBuilder<HODModel>(
        future: scraper.getHODDetails(url),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF3E8E)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: TextStyle(color: textColor),
              ),
            );
          }
          final hod = snapshot.data!;
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    if (hod.imageUrl.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => FullScreenImageViewer(
                                imageUrl: hod.imageUrl,
                                heroTag: 'hod_img',
                                postId: null, // No dummy ID
                              ),
                        ),
                      );
                    }
                  },
                  child: Hero(
                    tag: 'hod_img',
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF00C6FB), Color(0xFF005BEA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 70,
                          backgroundColor:
                              isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                          // Used CachedNetworkImageProvider here to satisfy the unused import error
                          backgroundImage:
                              hod.imageUrl.isNotEmpty
                                  ? CachedNetworkImageProvider(hod.imageUrl)
                                  : null,
                          child:
                              hod.imageUrl.isEmpty
                                  ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color:
                                        isDark ? Colors.white54 : Colors.grey,
                                  )
                                  : null,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  hod.name,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  hod.designation,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF00C6FB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C6FB).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.format_quote_rounded,
                              color: Color(0xFF00C6FB),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Message from HOD",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        hod.message.isNotEmpty
                            ? hod.message
                            : "No message available.",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          height: 1.6,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
