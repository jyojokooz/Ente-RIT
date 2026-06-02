// ===============================
// FILE NAME: home_quick_links.dart
// FILE PATH: lib/widgets/home/home_quick_links.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_project/core/config/feature_config.dart';

class HomeQuickLinksBar extends StatelessWidget {
  final bool isDark;
  const HomeQuickLinksBar({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // We perfectly match the colors and icons from your reference image,
    // linking them to actual screens in your app.
    final List<Map<String, dynamic>> items = [
      {
        'label': 'Rooms',
        'icon': Icons.groups_rounded,
        'color': const Color(0xFFB165FF), // Neon Purple
        'id': 'peer_rooms',
      },
      {
        'label': 'Events',
        'icon': Icons.calendar_month_rounded,
        'color': const Color(0xFFFF4B72), // Neon Pink
        'id': 'events',
      },
      {
        'label': 'Buses',
        'icon': Icons.directions_bus_rounded,
        'color': const Color(0xFF00C6FB), // Neon Blue
        'id': 'bus_tracker',
      },
      {
        'label': 'News',
        'icon': Icons.campaign_rounded, // Megaphone icon
        'color': const Color(0xFFFF9A44), // Neon Orange
        'id': 'tech_news',
      },
      {
        'label': 'Lost',
        'icon': Icons.inventory_2_rounded, // Box icon
        'color': const Color(0xFF43E97B), // Neon Green
        'id': 'lost_and_found',
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
        ],
        border:
            isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length * 2 - 1, (index) {
          // Add subtle vertical dividers between items
          if (index.isOdd) {
            return Container(
              width: 1,
              height: 30,
              color: isDark ? Colors.white10 : Colors.black12,
            );
          }
          final itemIndex = index ~/ 2;
          final item = items[itemIndex];
          return _buildLinkItem(context, item, isDark);
        }),
      ),
    );
  }

  Widget _buildLinkItem(
    BuildContext context,
    Map<String, dynamic> item,
    bool isDark,
  ) {
    final Color iconColor = item['color'];

    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Open the configured screen when tapped
          final config = FeatureConfig.featureMap[item['id']];
          if (config != null && config['screen'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => config['screen']),
            );
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- GLOWING ICON STACK ---
            Stack(
              alignment: Alignment.center,
              children: [
                // Hidden container that projects the neon glow shadow
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.6),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                // Actual Icon
                Icon(item['icon'], color: iconColor, size: 24),
              ],
            ),
            const SizedBox(height: 8),

            // Label
            Text(
              item['label'],
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
