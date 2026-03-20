// ===============================
// FILE PATH: lib/widgets/profile/profile_quick_access.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../screens/driver_tracking_screen.dart';
import '../../screens/cafeteria_dashboard_screen.dart';

class ProfileQuickAccess extends StatelessWidget {
  final String role;
  final bool isAdmin;
  final Color cardColor;
  final Color textColor;

  const ProfileQuickAccess({
    super.key,
    required this.role,
    required this.isAdmin,
    required this.cardColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Only render the box if the user actually has a specialized role
    if (role != 'driver' && role != 'cafeteria_admin') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: textColor),
              const SizedBox(width: 12),
              Text(
                "Work Tools",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: textColor,
                ),
              ),
              const Spacer(),
              const Text("💼", style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (role == 'driver')
                  _buildCircleButton(
                    context,
                    Icons.local_shipping_rounded,
                    const Color(0xFFFF3E8E),
                    isDark,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DriverTrackingScreen(),
                      ),
                    ),
                  ),
                if (role == 'cafeteria_admin')
                  _buildCircleButton(
                    context,
                    Icons.fastfood_rounded,
                    const Color(0xFFFF9A44),
                    isDark,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CafeteriaDashboardScreen(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(
    BuildContext context,
    IconData icon,
    Color iconColor,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161618) : Colors.grey.shade100,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 2,
          ),
        ),
        child: Icon(icon, color: iconColor, size: 28),
      ),
    );
  }
}
