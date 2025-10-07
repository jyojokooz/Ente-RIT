// lib/auth/auth_gate.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Import the possible destinations from this gate.
import 'package:my_project/screens/create_username_screen.dart';
import 'package:my_project/screens/main_screen.dart';

// --- THE FIX ---
// Use the full package path to import AuthScreen, as it's in a different folder.
import 'package:my_project/screens/auth_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }

          if (authSnapshot.hasData) {
            return FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(authSnapshot.data!.uid)
                      .get(),
              builder: (context, userDocSnapshot) {
                if (userDocSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.yellow),
                  );
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
            // Because AuthScreen is now correctly imported, this line will work.
            return const AuthScreen();
          }
        },
      ),
    );
  }
}
