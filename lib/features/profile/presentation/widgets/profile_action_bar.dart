// ===============================
// FILE NAME: profile_action_bar.dart
// FILE PATH: lib/features/profile/presentation/widgets/profile_action_bar.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_project/features/profile/domain/connection_status.dart';

class ProfileActionBar extends StatelessWidget {
  final bool isCurrentUser;
  final ConnectionStatus connectionStatus;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final VoidCallback onEditProfile;
  final VoidCallback onShareProfile;
  final Function(String) onConnectionAction;
  final VoidCallback onMessage;

  const ProfileActionBar({
    super.key,
    required this.isCurrentUser,
    required this.connectionStatus,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.onEditProfile,
    required this.onShareProfile,
    required this.onConnectionAction,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final outlinedButtonStyle = OutlinedButton.styleFrom(
      foregroundColor: textColor,
      backgroundColor: cardColor,
      side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );

    final filledButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF673AB7),
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );

    if (isCurrentUser) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: outlinedButtonStyle,
              icon: Icon(Icons.edit_outlined, size: 18, color: textColor),
              onPressed: onEditProfile,
              label: Text(
                "Edit Profile",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              style: filledButtonStyle,
              icon: const Icon(Icons.share_outlined, size: 18),
              onPressed: onShareProfile,
              label: Text(
                "Share Profile",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      );
    }

    String primaryLabel = "Mingle";
    IconData primaryIcon = Icons.person_add_outlined;
    VoidCallback? primaryAction = () => onConnectionAction('send');
    bool isPrimaryFilled = true;

    if (connectionStatus == ConnectionStatus.connected) {
      primaryLabel = "Message";
      primaryIcon = Icons.chat_bubble_outline;
      primaryAction = onMessage;
      isPrimaryFilled = false;
    } else if (connectionStatus == ConnectionStatus.sent) {
      primaryLabel = "Requested";
      primaryIcon = Icons.access_time;
      primaryAction = () => onConnectionAction('cancel');
      isPrimaryFilled = false;
    } else if (connectionStatus == ConnectionStatus.received) {
      primaryLabel = "Accept";
      primaryIcon = Icons.check;
      primaryAction = () => onConnectionAction('accept');
    }

    return Row(
      children: [
        Expanded(
          child:
              isPrimaryFilled
                  ? ElevatedButton.icon(
                    style: filledButtonStyle,
                    onPressed: primaryAction,
                    icon: Icon(primaryIcon, size: 18),
                    label: Text(
                      primaryLabel,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  )
                  : OutlinedButton.icon(
                    style: outlinedButtonStyle,
                    onPressed: primaryAction,
                    icon: Icon(primaryIcon, size: 18),
                    label: Text(
                      primaryLabel,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
        ),
        if (connectionStatus == ConnectionStatus.connected) ...[
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              style: outlinedButtonStyle,
              icon: const Icon(Icons.person_remove_outlined, size: 18),
              onPressed: () => onConnectionAction('remove'),
              label: Text(
                "Disconnect",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
