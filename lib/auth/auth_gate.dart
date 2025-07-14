import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_project/screens/home_screen.dart';
import 'package:my_project/screens/welcome_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        // Listen to Firebase's real-time authentication state
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If the connection is still loading data, show a spinner
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }

          // If the snapshot has data, it means the user IS logged in
          if (snapshot.hasData) {
            // So, show the main app (HomeScreen)
            return const HomeScreen();
          }
          // Otherwise, the user is NOT logged in
          else {
            // So, show the entry point for logged-out users
            return const WelcomeScreen();
          }
        },
      ),
    );
  }
}
