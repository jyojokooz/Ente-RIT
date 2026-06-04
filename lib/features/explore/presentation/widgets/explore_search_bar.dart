// ===============================
// FILE NAME: explore_search_bar.dart
// FILE PATH: lib/features/explore/presentation/widgets/explore_search_bar.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExploreSearchBar extends StatelessWidget {
  final Color cardColor;
  final Color subtitleColor;
  final bool isDark;
  final VoidCallback onTap;

  const ExploreSearchBar({
    super.key,
    required this.cardColor,
    required this.subtitleColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: subtitleColor),
            const SizedBox(width: 12),
            Text(
              'Search for users...',
              style: GoogleFonts.poppins(color: subtitleColor, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
