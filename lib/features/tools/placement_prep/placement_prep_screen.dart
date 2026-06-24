// ===============================
// FILE NAME: placement_prep_screen.dart
// FILE PATH: lib/features/tools/placement_prep/placement_prep_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class PlacementPrepScreen extends StatelessWidget {
  const PlacementPrepScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF1C1C22) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Placement Prep',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          // Hero Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8A65), Color(0xFFFF5722)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5722).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crack Your Dream Job',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Resources, aptitude tests, and interview guides.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.work_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Practice Resources',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),

          _PrepCard(
            title: 'Aptitude Tests',
            description: 'Practice quantitative, logical, and verbal questions.',
            icon: Icons.calculate_rounded,
            color: const Color(0xFF7B61FF),
            cardColor: cardColor,
            textColor: textColor,
            subtitleColor: subtitleColor,
            onTap: () => _launchUrl('https://www.indiabix.com/'),
          ),
          const SizedBox(height: 12),
          _PrepCard(
            title: 'Coding Practice',
            description: 'LeetCode, HackerRank, and DSA sheets.',
            icon: Icons.code_rounded,
            color: const Color(0xFF00B4D8),
            cardColor: cardColor,
            textColor: textColor,
            subtitleColor: subtitleColor,
            onTap: () => _launchUrl('https://leetcode.com/'),
          ),
          const SizedBox(height: 12),
          _PrepCard(
            title: 'Interview Core',
            description: 'OS, DBMS, Computer Networks, and OOPS.',
            icon: Icons.storage_rounded,
            color: const Color(0xFF43E97B),
            cardColor: cardColor,
            textColor: textColor,
            subtitleColor: subtitleColor,
            onTap: () => _launchUrl('https://www.geeksforgeeks.org/'),
          ),

          const SizedBox(height: 32),
          Text(
            'Top Recruiters',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _CompanyChip('TCS', isDark),
              _CompanyChip('Infosys', isDark),
              _CompanyChip('Wipro', isDark),
              _CompanyChip('Cognizant', isDark),
              _CompanyChip('IBS', isDark),
              _CompanyChip('Qburst', isDark),
              _CompanyChip('SOTI', isDark),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _PrepCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;
  final VoidCallback onTap;

  const _PrepCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: subtitleColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyChip extends StatelessWidget {
  final String name;
  final bool isDark;

  const _CompanyChip(this.name, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade300,
        ),
      ),
      child: Text(
        name,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
