// ===============================
// FILE NAME: main.dart
// FILE PATH: C:\Ente-RITEEE\Ente-RIT\lib\main.dart
// ===============================

// ===============================
// FILE PATH: lib/main.dart
// ===============================

// ignore_for_file: unnecessary_import

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for ultrafast theme loading

// --- FIXED IMPORTS: Using relative paths ---
import 'theme_provider.dart';
import 'auth/auth_gate.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';
import 'auth/forgot_password_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/search_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/requests_screen.dart';
import 'screens/create_username_screen.dart';
// --- END OF FIX ---

import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // OPTIMIZATION: Load Env, Firebase, and SharedPreferences concurrently!
  // This drastically reduces boot time and fixes the "white flash" issue.
  final futures = await Future.wait([
    dotenv.load(fileName: ".env"),
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    SharedPreferences.getInstance(),
  ]);

  // Extract the SharedPreferences instance from our concurrent load
  final prefs = futures[2] as SharedPreferences;

  // Check if dark mode is saved (defaults to false/light mode if never set)
  final isDark = prefs.getBool('isDarkMode') ?? false;

  // Initialize the global provider synchronously BEFORE the app runs
  themeProvider = ThemeProvider(isDark ? ThemeMode.dark : ThemeMode.light);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to theme changes dynamically
    return AnimatedBuilder(
      animation: themeProvider,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Kampus Konnect',

          // Pulls the mode instantly, no async delay causing white flashes
          themeMode: themeProvider.themeMode,

          // --- LIGHT THEME ---
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8F9FE), // Soft Light Grey
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF9983F3),
              secondary: Color(0xFF9983F3),
              surface: Colors.white,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textTheme: GoogleFonts.poppinsTextTheme(
              ThemeData.light().textTheme,
            ).apply(bodyColor: Colors.black87, displayColor: Colors.black87),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.black87),
              titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20),
            ),
            bottomAppBarTheme: const BottomAppBarThemeData(color: Colors.white),
            dividerColor: Colors.grey.shade200,
          ),

          // --- DARK THEME ---
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black, // True Black
            colorScheme: const ColorScheme.dark(
              primary: Colors.yellow,
              secondary: Colors.yellow,
              surface: Color(0xFF151515), // Very Dark Grey for cards
              onPrimary: Colors.black,
              onSurface: Colors.white,
            ),
            textTheme: GoogleFonts.poppinsTextTheme(
              ThemeData.dark().textTheme,
            ).apply(bodyColor: Colors.white, displayColor: Colors.white),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
            ),
            bottomAppBarTheme: BottomAppBarThemeData(
              color: Colors.grey.shade900,
            ),
            dividerColor: Colors.grey.shade800,
          ),

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
      },
    );
  }
}
