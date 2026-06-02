// ===============================
// FILE NAME: auth_gate.dart
// FILE PATH: lib/auth/auth_gate.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- RELATIVE IMPORTS ---
import 'package:my_project/features/auth/presentation/create_username_screen.dart';
import 'package:my_project/features/dashboard/presentation/main_screen.dart';
import 'package:my_project/features/auth/presentation/auth_screen.dart';

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

// --- UPDATED SKELETON LOADER ---
// Removed the giant placeholders and replaced with a tiny spinner
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
            // Top Nav Bar (Ente RIT + Icons)
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

            // Tiny Rotating Spinner just below the nav bar
            const Padding(
              padding: EdgeInsets.only(top: 40.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF9983F3), // Purple App Theme Color
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
