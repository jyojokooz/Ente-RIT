// ===============================
// FILE NAME: profile_top_card.dart
// FILE PATH: lib/features/profile/presentation/widgets/profile_top_card.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileTopCard extends StatelessWidget {
  final String profilePhotoUrl;
  final String displayName;
  final String department;
  final String bio;
  final bool isCurrentUser;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onViewStory;
  final VoidCallback onEditProfile;

  const ProfileTopCard({
    super.key,
    required this.profilePhotoUrl,
    required this.displayName,
    required this.department,
    required this.bio,
    required this.isCurrentUser,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.mutedColor,
    required this.onViewStory,
    required this.onEditProfile,
  });

  String _getAcronym(String name) {
    if (name.isEmpty) return "";
    String lowerName = name.toLowerCase();

    if (lowerName.contains("mca") || lowerName.contains("application"))
      return "MCA";
    if (lowerName.contains("computer")) return "CSE";
    if (lowerName.contains("mechanical")) return "ME";
    if (lowerName.contains("electrical") && lowerName.contains("electronics"))
      return "EEE";
    if (lowerName.contains("electronics") &&
        lowerName.contains("communication"))
      return "ECE";
    if (lowerName.contains("civil")) return "CE";
    if (lowerName.contains("architecture")) return "B.Arch";

    List<String> words = name.split(" ");
    if (words.length > 1) {
      return words.take(2).map((e) => e[0].toUpperCase()).join();
    }
    return name.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: onViewStory,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF673AB7), Color(0xFF3F51B5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      backgroundImage:
                          profilePhotoUrl.isNotEmpty
                              ? CachedNetworkImageProvider(profilePhotoUrl)
                              : null,
                      child:
                          profilePhotoUrl.isEmpty
                              ? Icon(Icons.person, color: mutedColor, size: 40)
                              : null,
                    ),
                  ),
                ),
              ),
              if (isCurrentUser)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onEditProfile,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF673AB7),
                        shape: BoxShape.circle,
                        border: Border.all(color: cardColor, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                if (department.isNotEmpty)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF673AB7).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getAcronym(department),
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF673AB7),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          department,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: mutedColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                if (bio.isNotEmpty)
                  Text(
                    bio,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: textColor.withOpacity(0.9),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
