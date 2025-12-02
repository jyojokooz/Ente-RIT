// ===============================
// FILE NAME: auth_gate.dart
// FILE PATH: lib/auth/auth_gate.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Import the possible destinations from this gate.
import 'package:my_project/screens/create_username_screen.dart';
import 'package:my_project/screens/main_screen.dart';
import 'package:my_project/screens/auth_screen.dart'; // The Welcome/Login page

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          // While checking auth status...
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            // Show a simple loading indicator. This screen is usually very fast.
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }

          // Case 1: USER IS LOGGED IN
          if (authSnapshot.hasData) {
            // Now, check if they have a username set up
            return FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(authSnapshot.data!.uid)
                      .get(),
              builder: (context, userDocSnapshot) {
                // While fetching user data...
                if (userDocSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.yellow),
                  );
                }

                // If user document doesn't exist OR username is missing...
                if (!userDocSnapshot.hasData || !userDocSnapshot.data!.exists) {
                  return const CreateUsernameScreen();
                }

                final userData =
                    userDocSnapshot.data!.data() as Map<String, dynamic>?;
                final username = userData?['username'] as String?;

                if (username == null || username.isEmpty) {
                  // Redirect to create username page
                  return const CreateUsernameScreen();
                }

                // SUCCESS: User is fully set up, go to home screen.
                return const MainScreen();
              },
            );
          }
          // Case 2: USER IS LOGGED OUT
          else {
            // Go to the Welcome/Login/Signup screen
            return const AuthScreen();
          }
        },
      ),
    );
  }
}
