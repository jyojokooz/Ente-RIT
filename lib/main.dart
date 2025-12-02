// ===============================
// FILE NAME: main.dart
// FILE PATH: lib/main.dart
// ===============================

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Screen Imports ---
import 'package:my_project/auth/auth_gate.dart';
import 'package:my_project/screens/main_screen.dart';
import 'package:my_project/screens/splash_screen.dart';
import 'package:my_project/auth/forgot_password_screen.dart';
import 'package:my_project/screens/create_post_screen.dart';
import 'package:my_project/screens/search_screen.dart';
import 'package:my_project/screens/chat_list_screen.dart';
import 'package:my_project/screens/requests_screen.dart';
import 'package:my_project/screens/create_username_screen.dart';

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
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Colors.yellow,
          secondary: Colors.yellow,
          surface: Colors.black,
          onPrimary: Colors.black,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
          decoration: TextDecoration.none,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade900,
          elevation: 0,
        ),
        // --- THIS IS THE FIX ---
        // Changed BottomAppBarTheme to BottomAppBarThemeData
        bottomAppBarTheme: const BottomAppBarThemeData(color: Colors.black87),
      ),

      // Always start with SplashScreen
      home: const SplashScreen(),

      routes: {
        '/auth-gate': (context) => const AuthGate(),
        '/home': (context) => const MainScreen(),
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
