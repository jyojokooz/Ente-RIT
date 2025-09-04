import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest.dart' as tz;

// --- Core App Entry Points ---
import 'package:my_project/auth/auth_gate.dart';
import 'package:my_project/screens/main_screen.dart';
import 'package:my_project/screens/splash_screen.dart';

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
  tz.initializeTimeZones();
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
        colorScheme: ColorScheme.dark(
          primary: Colors.yellow,
          secondary: Colors.yellow,
          // --- THIS IS THE FIX ---
          // Change the surface color from dark grey to pure black.
          surface: Colors.black,
          onPrimary: Colors.black,
          onSurface: Colors.white,
        ),
        // We also explicitly set the scaffold background to black for consistency.
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
        bottomAppBarTheme: BottomAppBarTheme(color: Colors.grey.shade900),
      ),

      home: const SplashScreen(),

      routes: {
        '/auth-gate': (context) => const AuthGate(),
        '/home': (context) => const MainScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/create-post': (context) => const CreatePostScreen(),
        '/search': (context) => const SearchScreen(),
        '/requests': (context) => const RequestsScreen(),
        '/chat-list': (context) => const ChatListScreen(),
      },
    );
  }
}
