// ===============================
// FILE NAME: likes_list_screen.dart
// FILE PATH: lib/screens/likes_list_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'pages/profile_screen.dart';

class LikesListScreen extends StatelessWidget {
  final List<dynamic> likeUserIds;

  const LikesListScreen({super.key, required this.likeUserIds});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Likes",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body:
          likeUserIds.isEmpty
              ? Center(
                child: Text(
                  "No likes yet.",
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              )
              : ListView.builder(
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
                        return const ListTile(
                          leading: CircleAvatar(backgroundColor: Colors.grey),
                          title: Text("Loading..."),
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

                      return ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ProfileScreen(userId: userId),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              profilePic.isNotEmpty
                                  ? CachedNetworkImageProvider(profilePic)
                                  : null,
                          child:
                              profilePic.isEmpty
                                  ? const Icon(Icons.person, color: Colors.grey)
                                  : null,
                        ),
                        title: Text(
                          displayName,
                          // FIX: Explicitly set color to Black
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          "@$username",
                          // FIX: Explicitly set color to Dark Grey
                          style: GoogleFonts.poppins(
                            color: Colors.grey[700],
                            fontSize: 12,
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
