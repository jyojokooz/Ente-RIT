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
import 'package:shared_preferences/shared_preferences.dart';

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
import 'screens/pages/profile_screen.dart'; // <-- ADDED: Needed for dynamic QR routing

import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final futures = await Future.wait([
    dotenv.load(fileName: ".env"),
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    SharedPreferences.getInstance(),
  ]);

  final prefs = futures[2] as SharedPreferences;
  final isDark = prefs.getBool('isDarkMode') ?? false;

  themeProvider = ThemeProvider(isDark ? ThemeMode.dark : ThemeMode.light);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeProvider,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Ente RIT',
          themeMode: themeProvider.themeMode,

          // --- LIGHT THEME ---
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8F9FE),
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
            scaffoldBackgroundColor: Colors.black,
            colorScheme: const ColorScheme.dark(
              primary: Colors.yellow,
              secondary: Colors.yellow,
              surface: Color(0xFF151515),
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

          // Static Routes
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

          // --- THE FIX: DYNAMIC ROUTING FOR QR CODES ---
          // This catches URLs like /profile/12345 or /verify/12345 and routes them
          onGenerateRoute: (settings) {
            final uri = Uri.tryParse(settings.name ?? '');

            if (uri != null && uri.pathSegments.length == 2) {
              final routeName = uri.pathSegments[0]; // e.g., 'profile'
              final userId = uri.pathSegments[1]; // e.g., 'USER_UID'

              // Handle Profile QR Scans
              if (routeName == 'profile') {
                return MaterialPageRoute(
                  builder: (context) => ProfileScreen(userId: userId),
                );
              }

              // Handle ID Card Verification QR Scans
              if (routeName == 'verify') {
                return MaterialPageRoute(
                  builder: (context) => ProfileScreen(userId: userId),
                );
              }
            }
            return null; // Fallback to default
          },
        );
      },
    );
  }
}
