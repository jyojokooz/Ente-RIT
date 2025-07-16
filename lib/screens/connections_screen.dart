import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_screen.dart';

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
                      if (!userSnapshot.hasData) {
                        // You can return a shimmer/loading effect here
                        return const ListTile(title: Text('Loading...'));
                      }
                      if (!userSnapshot.data!.exists) {
                        return const SizedBox.shrink(); // Don't show if user was deleted
                      }
                      final userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                      final userImage = userData['profilePhotoUrl'] ?? '';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              userImage.isNotEmpty
                                  ? NetworkImage(userImage)
                                  : null,
                          child:
                              userImage.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                        ),
                        title: Text(userData['displayName'] ?? 'A User'),
                        subtitle: Text('@${userData['username'] ?? ''}'),
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
