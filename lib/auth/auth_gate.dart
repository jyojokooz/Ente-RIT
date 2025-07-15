import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_project/screens/home_screen.dart';
import 'package:my_project/screens/splash_screen.dart'; // <-- Import SplashScreen

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        // Listen to Firebase's real-time authentication state
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // --- While waiting for the auth state, show a simple loading indicator ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }

          // --- If the snapshot has data, the user IS logged in ---
          if (snapshot.hasData) {
            // Go directly to the HomeScreen, completely skipping the splash animation.
            return const HomeScreen();
          }
          // --- Otherwise, the user is NOT logged in ---
          else {
            // Show the SplashScreen, which will run its animation
            // and then navigate to the WelcomeScreen on completion.
            // This perfectly matches your requirement.
            return const SplashScreen();
          }
        },
      ),
    );
  }
}
