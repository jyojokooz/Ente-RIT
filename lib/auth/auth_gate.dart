import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Import the two possible destinations from this gate.
import 'package:my_project/screens/main_screen.dart';
import 'package:my_project/screens/splash_screen.dart';

/// AuthGate is the first widget that decides which screen to show the user.
///
/// It listens to the Firebase authentication state and acts as a router:
/// - If the user is logged in, it shows the main app content (`MainScreen`).
/// - If the user is logged out, it shows the entry flow (`SplashScreen`).
/// - While checking, it shows a loading indicator.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        // This stream from Firebase emits a User object when the user is signed in,
        // and null when they are signed out. It updates in real-time.
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // STATE 1: Waiting for connection
          // While the stream is connecting to Firebase to check the auth state,
          // we show a loading indicator to prevent a blank screen.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }

          // STATE 2: User is LOGGED IN
          // The snapshot has data, which means a User object was received.
          if (snapshot.hasData) {
            // Navigate to MainScreen. This is the correct entry point for the
            // main app, as it contains the bottom navigation bar and manages
            // the Home, Classify, and Profile pages.
            return const MainScreen();
          }
          // STATE 3: User is LOGGED OUT
          // The snapshot has no data, meaning the user is not signed in.
          else {
            // Show the SplashScreen. The SplashScreen will then handle its
            // animation and navigate to the WelcomeScreen when it's done.
            return const SplashScreen();
          }
        },
      ),
    );
  }
}
