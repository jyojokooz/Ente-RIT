// ===============================
// FILE NAME: likes_list_screen.dart
// FILE PATH: lib/screens/likes_list_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_project/features/profile/presentation/profile_screen.dart';

class LikesListScreen extends StatelessWidget {
  final List<dynamic> likeUserIds;

  const LikesListScreen({super.key, required this.likeUserIds});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Custom colors matching the modern design
    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedTextColor = isDark ? Colors.white54 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Likes",
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body:
          likeUserIds.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 60,
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No likes yet.",
                      style: GoogleFonts.poppins(
                        color: mutedTextColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: likeUserIds.length,
                itemBuilder: (context, index) {
                  final userId = likeUserIds[index];

                  return FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          height: 70,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      }

                      if (!snapshot.data!.exists) {
                        return const SizedBox.shrink();
                      }

                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final profilePic = userData['profilePhotoUrl'] ?? '';
                      final displayName = userData['displayName'] ?? 'User';
                      final username = userData['username'] ?? '';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ProfileScreen(userId: userId),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
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
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFFF3E8E),
                                      Color(0xFFFF9A44),
                                    ], // Pink to Orange gradient
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
                                    radius: 24,
                                    backgroundColor:
                                        isDark
                                            ? Colors.grey.shade800
                                            : Colors.grey.shade200,
                                    backgroundImage:
                                        profilePic.isNotEmpty
                                            ? CachedNetworkImageProvider(
                                              profilePic,
                                            )
                                            : null,
                                    child:
                                        profilePic.isEmpty
                                            ? Icon(
                                              Icons.person,
                                              color: mutedTextColor,
                                            )
                                            : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      displayName,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      "@$username",
                                      style: GoogleFonts.poppins(
                                        color: mutedTextColor,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: mutedTextColor,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
