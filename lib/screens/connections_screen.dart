// ===============================
// FILE NAME: connections_screen.dart
// FILE PATH: lib/screens/connections_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'pages/profile_screen.dart';

class ConnectionsScreen extends StatelessWidget {
  final String title;
  final List<dynamic> userIds;

  const ConnectionsScreen({
    super.key,
    required this.title,
    required this.userIds,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body:
          userIds.isEmpty
              ? Center(
                child: Text(
                  'No connections yet.',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: userIds.length,
                itemBuilder: (context, index) {
                  final userId = userIds[index];

                  // Fetch each user's data individually
                  return FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .get(),
                    builder: (context, userSnapshot) {
                      // 1. Loading State
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const _ConnectionListTilePlaceholder();
                      }

                      // 2. Error/Deleted User State (THE FIX)
                      // If the user document doesn't exist, we show a placeholder instead of hiding it.
                      // This ensures the list count matches the profile count.
                      if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            child: const Icon(
                              Icons.person_off,
                              color: Colors.grey,
                            ),
                          ),
                          title: Text(
                            "Account Unavailable",
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        );
                      }

                      // 3. Success State
                      final userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                      final userImage = userData['profilePhotoUrl'] as String?;
                      final displayName =
                          userData['displayName'] ?? 'Unknown User';
                      final username = userData['username'] ?? 'unknown';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              (userImage != null && userImage.isNotEmpty)
                                  ? NetworkImage(userImage)
                                  : null,
                          child:
                              (userImage == null || userImage.isEmpty)
                                  ? const Icon(Icons.person, color: Colors.grey)
                                  : null,
                        ),
                        title: Text(
                          displayName,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          '@$username',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ProfileScreen(userId: userId),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
    );
  }
}

/// A placeholder widget with a shimmer effect for loading list tiles.
class _ConnectionListTilePlaceholder extends StatelessWidget {
  const _ConnectionListTilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.white),
        title: Container(height: 16.0, width: 150.0, color: Colors.white),
        subtitle: Container(height: 12.0, width: 100.0, color: Colors.white),
      ),
    );
  }
}
