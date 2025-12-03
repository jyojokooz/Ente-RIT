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
          // 1. Waiting for Auth: Show exact Home Skeleton
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const _HomeSkeletonLoader();
          }

          if (authSnapshot.hasData) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(authSnapshot.data!.uid)
                  .get(),
              builder: (context, userDocSnapshot) {
                // 2. Waiting for User Data: Keep showing Home Skeleton
                if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                  return const _HomeSkeletonLoader();
                }

                if (!userDocSnapshot.hasData || !userDocSnapshot.data!.exists) {
                  return const CreateUsernameScreen();
                }

                final userData =
                    userDocSnapshot.data!.data() as Map<String, dynamic>?;
                final username = userData?['username'] as String?;

                if (username == null || username.isEmpty) {
                  return const CreateUsernameScreen();
                }

                // SUCCESS: Seamless transition to Main Screen
                return const MainScreen();
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
    // Manually matching the MainScreen AppBar structure
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Fake Top Bar (Matches MainScreen _buildTopBar)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kampus Konnect',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.favorite_border, color: Colors.black, size: 28),
                      const SizedBox(width: 8),
                      const Icon(Icons.chat_bubble_outline, color: Colors.black, size: 26),
                    ],
                  ),
                ],
              ),
            ),
            // Fake Content List
            Expanded(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(), // Prevent user interaction during load
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