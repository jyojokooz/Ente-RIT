// ===============================
// FILE PATH: lib/auth/auth_gate.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- RELATIVE IMPORTS ---
import '../screens/create_username_screen.dart';
import '../screens/main_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/post_card_placeholder.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const _HomeSkeletonLoader();
          }

          if (authSnapshot.hasData) {
            final user = authSnapshot.data!;

            return StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
              builder: (context, userDocSnapshot) {
                if (userDocSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const _HomeSkeletonLoader();
                }

                if (userDocSnapshot.hasData && userDocSnapshot.data!.exists) {
                  final userData =
                      userDocSnapshot.data!.data() as Map<String, dynamic>?;
                  final username = userData?['username'] as String?;

                  if (username == null || username.isEmpty) {
                    return const CreateUsernameScreen();
                  }

                  return const MainScreen();
                }

                return const _HomeSkeletonLoader();
              },
            );
          } else {
            // This safely returns the AuthScreen class imported from ../screens/auth_screen.dart
            return const AuthScreen();
          }
        },
      ),
    );
  }
}

class _HomeSkeletonLoader extends StatelessWidget {
  const _HomeSkeletonLoader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: bgColor,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ente RIT',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.favorite_border, color: textColor, size: 28),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chat_bubble_outline,
                        color: textColor,
                        size: 26,
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
