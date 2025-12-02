// ===============================
// FILE NAME: auth_gate.dart
// FILE PATH: lib/auth/auth_gate.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart'; // Ensure shimmer is imported

// Import destinations
import 'package:my_project/screens/create_username_screen.dart';
import 'package:my_project/screens/main_screen.dart';
import 'package:my_project/screens/auth_screen.dart';
import 'package:my_project/screens/post_card_placeholder.dart'; // Import your placeholder

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          // 1. While waiting for Auth, show the HOME SKELETON instead of a spinner
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
                // 2. While waiting for User Data, keep showing the HOME SKELETON
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
// This looks exactly like your Home Screen but with Shimmer effects.
// This prevents the "White screen with Spinner" jar.
class _HomeSkeletonLoader extends StatelessWidget {
  const _HomeSkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Kampus Konnect',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: ListView.builder(
        // Disable scrolling on the skeleton
        physics: const NeverScrollableScrollPhysics(), 
        itemCount: 3,
        itemBuilder: (context, index) => const PostCardPlaceholder(),
      ),
    );
  }
}