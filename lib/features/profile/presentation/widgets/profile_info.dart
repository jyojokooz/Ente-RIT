// ===============================
// FILE PATH: lib/widgets/profile/profile_info.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_project/features/profile/domain/connection_status.dart';

class ProfileInfo extends StatelessWidget {
  final String displayName;
  final String username;
  final String department;
  final String bio;
  final int postCount;
  final int mingleCount;
  final bool isCurrentUser;
  final ConnectionStatus connectionStatus;

  final Color textColor;
  final Color mutedTextColor;
  final Color cardColor;

  final VoidCallback onEditProfile;
  final VoidCallback onShareProfile;
  final VoidCallback onViewMingles;
  final VoidCallback onPostCountTap; // <-- NEW
  final Function(String) onConnectionAction;
  final VoidCallback onMessage;

  const ProfileInfo({
    super.key,
    required this.displayName,
    required this.username,
    required this.department,
    required this.bio,
    required this.postCount,
    required this.mingleCount,
    required this.isCurrentUser,
    required this.connectionStatus,
    required this.textColor,
    required this.mutedTextColor,
    required this.cardColor,
    required this.onEditProfile,
    required this.onShareProfile,
    required this.onViewMingles,
    required this.onPostCountTap, // <-- NEW
    required this.onConnectionAction,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          department.isNotEmpty ? department : '@$username',
          style: GoogleFonts.poppins(fontSize: 14, color: mutedTextColor),
        ),

        if (bio.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              bio,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textColor.withOpacity(0.85),
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Stats Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: onPostCountTap, // <-- Tap to scroll down to posts
              child: _buildStatCol(
                postCount.toString(),
                "Posts",
                textColor,
                mutedTextColor,
              ),
            ),
            Container(
              height: 40,
              width: 1,
              color: Colors.grey.withOpacity(0.3),
              margin: const EdgeInsets.symmetric(horizontal: 24),
            ),
            GestureDetector(
              onTap: onViewMingles,
              child: _buildStatCol(
                mingleCount.toString(),
                "Mingles",
                textColor,
                mutedTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        _buildActionButtons(),
      ],
    );
  }

  Widget _buildStatCol(String val, String label, Color tColor, Color mColor) {
    return Container(
      color: Colors.transparent, // Ensures the whole block is tappable
      child: Column(
        children: [
          Text(
            val,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: tColor,
            ),
          ),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: mColor)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (isCurrentUser) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: onEditProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: cardColor,
                foregroundColor: textColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                "Edit Profile",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF3E8E), Color(0xFFFF9A44)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ElevatedButton(
                onPressed: onShareProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  "Share Profile",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    String primaryLabel = "Mingle";
    VoidCallback? primaryAction = () => onConnectionAction('send');
    bool useGradient = true;

    if (connectionStatus == ConnectionStatus.connected) {
      primaryLabel = "Message";
      primaryAction = onMessage;
    } else if (connectionStatus == ConnectionStatus.sent) {
      primaryLabel = "Requested";
      primaryAction = () => onConnectionAction('cancel');
      useGradient = false;
    } else if (connectionStatus == ConnectionStatus.received) {
      primaryLabel = "Accept";
      primaryAction = () => onConnectionAction('accept');
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient:
                  useGradient
                      ? const LinearGradient(
                        colors: [Color(0xFFFF3E8E), Color(0xFFFF9A44)],
                      )
                      : null,
              color: useGradient ? null : cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ElevatedButton(
              onPressed: primaryAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: useGradient ? Colors.white : textColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                primaryLabel,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        if (connectionStatus == ConnectionStatus.connected) ...[
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => onConnectionAction('remove'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cardColor,
                foregroundColor: textColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                "Disconnect",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
