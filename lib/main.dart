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

        // --- THIS IS THE FIX ---
        // We take the Google Fonts text theme and then .apply() a global rule to it.
        // This rule tells all text styles in the theme to have NO underline decoration.
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: Colors.white, // You can set default colors here too
          displayColor: Colors.white,
          decoration: TextDecoration.none, // This removes the underlines
        ),

        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade900,
          elevation: 0,
        ),
        bottomAppBarTheme: BottomAppBarTheme(color: Colors.grey.shade900),
      ),
      home: const AuthGate(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/main': (context) => const MainScreen(),
        '/create-post': (context) => const CreatePostScreen(),
        '/search': (context) => const SearchScreen(),
        '/requests': (context) => const RequestsScreen(),
        '/chat-list': (context) => const ChatListScreen(),
      },
    );
  }
}
