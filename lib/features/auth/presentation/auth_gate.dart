import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

            // --- REQUIRE EMAIL VERIFICATION ---
            if (!user.emailVerified) {
              return const AuthScreen(); // Deny access to app
            }

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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // FIX: Display the actual image instead of text in the skeleton loader
                  Image.asset(
                    isDark
                        ? 'assets/enterit_logo.png'
                        : 'assets/enterit_logo_light.png',
                    height: 38,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            const SizedBox(width: 120, height: 38),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        color: textColor,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.maps_ugc_rounded, color: textColor, size: 26),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 40.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF9983F3),
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
