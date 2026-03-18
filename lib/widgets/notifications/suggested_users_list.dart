// ===============================
// FILE NAME: suggested_users_list.dart
// FILE PATH: lib/widgets/notifications/suggested_users_list.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../screens/pages/profile_screen.dart';

class SuggestedUsersList extends StatelessWidget {
  final Future<List<DocumentSnapshot>> suggestedUsersFuture;
  final bool isDark;
  final Color cardColor;
  final Color textColor;

  const SuggestedUsersList({
    super.key,
    required this.suggestedUsersFuture,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: suggestedUsersFuture,
      builder: (context, suggestionSnap) {
        if (!suggestionSnap.hasData) {
          return const SizedBox(
            height: 180,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF00C6FB)),
            ),
          );
        }

        final users = suggestionSnap.data!;
        if (users.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;
              final photoUrl = userData['profilePhotoUrl'] ?? '';
              final name = userData['displayName'] ?? 'User';
              final department = userData['department'] ?? 'Student';

              return GestureDetector(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(userId: userId),
                      ),
                    ),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor:
                            isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                        backgroundImage:
                            photoUrl.isNotEmpty
                                ? CachedNetworkImageProvider(photoUrl)
                                : null,
                        child:
                            photoUrl.isEmpty
                                ? Icon(
                                  Icons.person,
                                  color:
                                      isDark ? Colors.white54 : Colors.black54,
                                )
                                : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: textColor,
                        ),
                      ),
                      Text(
                        department,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
