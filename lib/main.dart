import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest.dart' as tz;

// --- Core Auth & Screens ---
import 'package:my_project/auth/auth_gate.dart';
import 'package:my_project/screens/welcome_screen.dart';
import 'package:my_project/auth/signup_screen.dart';
import 'package:my_project/auth/login_screen.dart';
import 'package:my_project/auth/forgot_password_screen.dart';
import 'package:my_project/screens/main_screen.dart'; // <-- IMPORT a MainScreen

// --- Other Standalone Screens ---
import 'package:my_project/screens/create_post_screen.dart';
import 'package:my_project/screens/search_screen.dart';
import 'package:my_project/screens/chat_list_screen.dart';
import 'package:my_project/screens/requests_screen.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the .env file
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Time Zone Database
  tz.initializeTimeZones();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Connect', // Changed to match your project's potential name
      // --- THEME DATA (Unchanged) ---
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.yellow,
          secondary: Colors.yellow,
          surface: Colors.grey.shade900,
          onPrimary: Colors.black,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade900,
          elevation: 0,
        ),
        bottomAppBarTheme: BottomAppBarTheme(color: Colors.grey.shade900),
      ),

      // AuthGate remains the entry point. It decides whether to show
      // the welcome screen or the main app.
      home: const AuthGate(),

      // --- ROUTES (Updated) ---
      // These routes are for full screens that are pushed on top of the stack.
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),

        // The new, single entry point for your main app experience
        '/main': (context) => const MainScreen(),

        // These routes are still valid as they lead to separate, full screens.
        '/create-post': (context) => const CreatePostScreen(),
        '/search': (context) => const SearchScreen(),
        '/requests': (context) => const RequestsScreen(),
        '/chat-list': (context) => const ChatListScreen(),

        // '/home', '/profile', and '/classify' have been REMOVED because they are
        // now part of MainScreen and should not be navigated to directly.
      },
    );
  }
}
