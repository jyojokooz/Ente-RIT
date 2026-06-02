// ===============================
// FILE NAME: empty_activity_state.dart
// FILE PATH: lib/widgets/notifications/empty_activity_state.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyActivityState extends StatelessWidget {
  final bool isDark;
  final Color textColor;

  const EmptyActivityState({
    super.key,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 20),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white10 : Colors.black12,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 60,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No recent activity',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When someone likes or comments on\nyour posts, it will show up here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
