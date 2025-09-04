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
import 'package:my_project/screens/main_screen.dart';

// --- Other Standalone Screens ---
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
      title: 'Campus Connect',
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
      // AuthGate will decide the first screen to show when the app starts
      home: const AuthGate(),

      // These routes are used for manual navigation with Navigator.pushNamed
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),

        // --- THIS IS THE UPDATED LINE ---
        // Changed '/main' to '/home' to match what your Login/Signup screens are calling.
        '/home': (context) => const MainScreen(),

        '/create-post': (context) => const CreatePostScreen(),
        '/search': (context) => const SearchScreen(),
        '/requests': (context) => const RequestsScreen(),
        '/chat-list': (context) => const ChatListScreen(),
      },
    );
  }
}
