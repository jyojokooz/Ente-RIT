// ===============================
// FILE PATH: lib/widgets/edit_profile/edit_profile_avatar.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditProfileAvatar extends StatelessWidget {
  final String? profilePhotoUrl;
  final bool isUploadingImage;
  final bool isDark;
  final Color bgColor;
  final Color subtitleColor;
  final VoidCallback onPickImage;

  const EditProfileAvatar({
    super.key,
    required this.profilePhotoUrl,
    required this.isUploadingImage,
    required this.isDark,
    required this.bgColor,
    required this.subtitleColor,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onPickImage,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            // Gradient Ring & Avatar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFF3E8E), Color(0xFFFF9A44)],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor:
                      isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  backgroundImage:
                      (profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty)
                          ? CachedNetworkImageProvider(profilePhotoUrl!)
                          : null,
                  child:
                      isUploadingImage
                          ? const CircularProgressIndicator(color: Colors.white)
                          : (profilePhotoUrl == null ||
                              profilePhotoUrl!.isEmpty)
                          ? Icon(Icons.person, size: 50, color: subtitleColor)
                          : null,
                ),
              ),
            ),
            // Camera Icon Badge
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF005BEA),
                shape: BoxShape.circle,
                border: Border.all(color: bgColor, width: 3),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
