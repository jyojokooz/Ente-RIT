// ===============================
// FILE NAME: auth_gate.dart
// FILE PATH: lib/auth/auth_gate.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import destinations
import 'package:my_project/screens/create_username_screen.dart';
import 'package:my_project/screens/main_screen.dart';
import 'package:my_project/screens/auth_screen.dart';
import 'package:my_project/screens/post_card_placeholder.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          // 1. Waiting for Auth
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const _HomeSkeletonLoader();
          }

          if (authSnapshot.hasData) {
            final user = authSnapshot.data!;

            // FIX: Changed from FutureBuilder to StreamBuilder
            // This listens continuously. When the signup function finishes writing
            // the user data to Firestore, this will auto-update and let the user in.
            return StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
              builder: (context, userDocSnapshot) {
                // 2. Waiting for Firestore connection
                if (userDocSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const _HomeSkeletonLoader();
                }

                // 3. User Document Exists
                if (userDocSnapshot.hasData && userDocSnapshot.data!.exists) {
                  final userData =
                      userDocSnapshot.data!.data() as Map<String, dynamic>?;
                  final username = userData?['username'] as String?;

                  if (username == null || username.isEmpty) {
                    return const CreateUsernameScreen();
                  }

                  // User is fully set up
                  return const MainScreen();
                }

                // 4. Document doesn't exist YET (Still being created by signup function)
                // Keep showing loader. Since this is a Stream, it will refresh automatically
                // the moment the document is created.
                return const _HomeSkeletonLoader();
              },
            );
          } else {
            return const AuthScreen();
          }
        },
      ),
    );
  }
}

// --- VISUAL FIX: Fake Home Screen ---
class _HomeSkeletonLoader extends StatelessWidget {
  const _HomeSkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ente RIT',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_border,
                        color: Colors.black,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.black,
                        size: 26,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Use ListView with physics NeverScrollable to prevent user interaction during load
            Expanded(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) => const PostCardPlaceholder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
