// ===============================
// FILE NAME: main.dart
// FILE PATH: lib/main.dart
// ===============================

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Core App Entry Points ---
import 'package:my_project/screens/main_screen.dart';
import 'package:my_project/screens/splash_screen.dart';
import 'package:my_project/screens/auth_screen.dart';
import 'package:my_project/screens/create_username_screen.dart';

// --- Other Standalone Screens ---
import 'package:my_project/auth/forgot_password_screen.dart';
import 'package:my_project/screens/create_post_screen.dart';
import 'package:my_project/screens/search_screen.dart';
import 'package:my_project/screens/chat_list_screen.dart';
import 'package:my_project/screens/requests_screen.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kampus Konnect',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF9983F3), // Brand Purple
          secondary: Colors.black,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSurface: Colors.black,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),

      // 1. 'home' defines the root widget (equivalent to route '/')
      home: const AuthStateWrapper(),

      // 2. Routes Map (REMOVED '/' from here)
      routes: {
        // '/auth-gate': (context) => const AuthGate(), // REMOVED
        // '/': (context) => const AuthStateWrapper(), // REMOVED: Caused the crash
        '/home': (context) => const MainScreen(),
        '/auth': (context) => const AuthScreen(),
        '/create-username': (context) => const CreateUsernameScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/create-post': (context) => const CreatePostScreen(),
        '/search': (context) => const SearchScreen(),
        '/requests': (context) => const RequestsScreen(),
        '/chat-list': (context) => const ChatListScreen(),
      },
    );
  }
}

// --- 1. Auth State Wrapper (Listens to Login/Logout) ---
class AuthStateWrapper extends StatelessWidget {
  const AuthStateWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Waiting for Auth API -> Show blank/white
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: Colors.white);
        }

        // 2. User is Logged In -> Check Database
        if (snapshot.hasData && snapshot.data != null) {
          // Use a Key to ensure this widget rebuilds correctly if user changes
          return UserDataCheck(
            key: ValueKey(snapshot.data!.uid),
            userId: snapshot.data!.uid,
          );
        }

        // 3. User is Logged Out -> Show Splash
        return const SplashScreen();
      },
    );
  }
}

// --- 2. User Data Check ---
class UserDataCheck extends StatefulWidget {
  final String userId;
  const UserDataCheck({super.key, required this.userId});

  @override
  State<UserDataCheck> createState() => _UserDataCheckState();
}

class _UserDataCheckState extends State<UserDataCheck> {
  late Future<DocumentSnapshot> _userDocFuture;

  @override
  void initState() {
    super.initState();
    // Initialize future once to prevent loops
    _userDocFuture =
        FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _userDocFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: Colors.white);
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final username = userData?['username'] as String?;

          if (username == null || username.isEmpty) {
            return const CreateUsernameScreen();
          }
          return const MainScreen();
        }

        // Fallback if user doc missing
        return const CreateUsernameScreen();
      },
    );
  }
}
