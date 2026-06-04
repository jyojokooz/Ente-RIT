// ===============================
// FILE NAME: profile_stats_bar.dart
// FILE PATH: lib/features/profile/presentation/widgets/profile_stats_bar.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileStatsBar extends StatelessWidget {
  final int postCount;
  final int mingleCount;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onScrollToPosts;
  final VoidCallback onViewMingles;

  const ProfileStatsBar({
    super.key,
    required this.postCount,
    required this.mingleCount,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.mutedColor,
    required this.onScrollToPosts,
    required this.onViewMingles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: onScrollToPosts,
            child: _buildStatColumn(
              Icons.article_outlined,
              postCount.toString(),
              "Posts",
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? Colors.white10 : Colors.black12,
          ),
          GestureDetector(
            onTap: onViewMingles,
            child: _buildStatColumn(
              Icons.people_outline_rounded,
              mingleCount.toString(),
              "Mingles",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(IconData icon, String count, String label) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF673AB7), size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: mutedColor),
          ),
        ],
      ),
    );
  }
}
