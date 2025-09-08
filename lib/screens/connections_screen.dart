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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey.shade900,
      ),
      body:
          userIds.isEmpty
              ? Center(
                child: Text(
                  'No connections to show.',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              )
              : ListView.builder(
                itemCount: userIds.length,
                itemBuilder: (context, index) {
                  final userId = userIds[index];
                  // Use a FutureBuilder to fetch each user's profile data
                  return FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .get(),
                    builder: (context, userSnapshot) {
                      // While loading, show the shimmer placeholder
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const _ConnectionListTilePlaceholder();
                      }

                      // Handle errors during fetch
                      if (userSnapshot.hasError) {
                        return const ListTile(
                          leading: CircleAvatar(
                            child: Icon(Icons.error_outline),
                          ),
                          title: Text('Could not load user'),
                        );
                      }

                      // Handle case where user document doesn't exist (e.g., deleted account)
                      if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                        return const SizedBox.shrink(); // Don't show anything
                      }

                      // If data is available, display the user info
                      final userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                      final userImage = userData['profilePhotoUrl'] as String?;
                      final displayName =
                          userData['displayName'] ?? 'Unknown User';
                      final username = userData['username'] ?? 'unknown';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              (userImage != null && userImage.isNotEmpty)
                                  ? NetworkImage(userImage)
                                  : null,
                          child:
                              (userImage == null || userImage.isEmpty)
                                  ? const Icon(Icons.person)
                                  : null,
                        ),
                        title: Text(
                          displayName,
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        subtitle: Text(
                          '@$username',
                          style: GoogleFonts.poppins(color: Colors.white70),
                        ),
                        onTap: () {
                          // Navigate to the tapped user's profile
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
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade700,
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.white),
        title: Container(height: 16.0, width: 150.0, color: Colors.white),
        subtitle: Container(height: 12.0, width: 100.0, color: Colors.white),
      ),
    );
  }
}
