// ===============================
// FILE NAME: profile_header.dart
// FILE PATH: lib/widgets/profile/profile_header.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileHeader extends StatelessWidget {
  final bool isCurrentUser;
  final String? profilePhotoUrl;
  final Color bgColor;
  final Color textColor;
  final bool isDark;
  final VoidCallback onBack;
  final VoidCallback onSettings;
  final VoidCallback onAvatarTap;

  const ProfileHeader({
    super.key,
    required this.isCurrentUser,
    this.profilePhotoUrl,
    required this.bgColor,
    required this.textColor,
    required this.isDark,
    required this.onBack,
    required this.onSettings,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Cover Image / Background Fade
        Container(
          height: 240,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isDark ? Colors.black.withOpacity(0.8) : Colors.grey.shade300,
                bgColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!isCurrentUser)
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, color: textColor),
                      onPressed: onBack,
                    )
                  else
                    const SizedBox(width: 48),
                  if (isCurrentUser)
                    IconButton(
                      icon: Icon(Icons.settings_outlined, color: textColor),
                      onPressed: onSettings,
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),

        // Overlapping Gradient Avatar
        Positioned(
          bottom: 0,
          child: GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFF3E8E),
                    Color(0xFFFF9A44),
                  ], // Pink to Orange
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
                  radius: 55,
                  backgroundColor: Colors.grey.shade800,
                  backgroundImage:
                      (profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty)
                          ? CachedNetworkImageProvider(profilePhotoUrl!)
                          : const AssetImage('assets/default_avatar.png')
                              as ImageProvider,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
