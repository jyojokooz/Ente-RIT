// ===============================
// FILE PATH: lib/main.dart
// ===============================

// ignore_for_file: unnecessary_import

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <-- RIVERPOD ADDED

import 'package:my_project/firebase_options.dart';
import 'package:my_project/core/constants/theme_provider.dart';

import 'package:my_project/features/auth/presentation/auth_gate.dart';
import 'package:my_project/features/dashboard/presentation/main_screen.dart';
import 'package:my_project/features/dashboard/presentation/splash_screen.dart';
import 'package:my_project/features/auth/presentation/forgot_password_screen.dart';
import 'package:my_project/features/posts/presentation/create_post_screen.dart';
import 'package:my_project/features/explore/presentation/search_screen.dart';
import 'package:my_project/features/chat/presentation/chat_list_screen.dart';
import 'package:my_project/features/profile/presentation/requests_screen.dart';
import 'package:my_project/features/auth/presentation/create_username_screen.dart';
import 'package:my_project/features/profile/presentation/profile_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Ignore duplicate app error in background
  }
  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Safely load env variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("DotEnv Error: $e");
  }

  // 2. Safely initialize Firebase (Catches the Duplicate App Error)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase Init Error (Safe to ignore): $e");
  }

  // 3. Load SharedPreferences BEFORE the app runs
  final prefs = await SharedPreferences.getInstance();

  // 4. Safely set Firestore settings
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    debugPrint("Firestore settings already set: $e");
  }

  // 5. Setup Background Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 6. FINALLY, Start the App UI with ProviderScope
  runApp(
    ProviderScope(
      overrides: [
        // This injects the loaded SharedPreferences into Riverpod synchronously!
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

// 7. Changed to ConsumerWidget to listen to Riverpod states
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the theme state directly (No more AnimatedBuilder!)
    final currentThemeMode = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ente RIT',
      themeMode: currentThemeMode,

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
        bottomAppBarTheme: BottomAppBarThemeData(color: Colors.grey.shade900),
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

      // --- DYNAMIC ROUTING FOR QR CODES ---
      onGenerateRoute: (settings) {
        final uri = Uri.tryParse(settings.name ?? '');

        if (uri != null && uri.pathSegments.length == 2) {
          final routeName = uri.pathSegments[0];
          final userId = uri.pathSegments[1];

          if (routeName == 'profile' || routeName == 'verify') {
            return MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: userId),
            );
          }
        }
        return null;
      },
    );
  }
}
