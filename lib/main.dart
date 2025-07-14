import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:my_project/auth/auth_gate.dart';
import 'package:my_project/screens/welcome_screen.dart';
import 'package:my_project/auth/signup_screen.dart';
import 'package:my_project/auth/login_screen.dart';
import 'package:my_project/auth/forgot_password_screen.dart';
import 'package:my_project/screens/home_screen.dart';
import 'package:my_project/screens/profile_screen.dart';
import 'package:my_project/screens/create_post_screen.dart';
import 'package:my_project/screens/classify_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Social App',

      theme: ThemeData(
        brightness: Brightness.dark,

        // --- FIX APPLIED HERE ---
        // The `background` property has been removed from the ColorScheme.
        colorScheme: ColorScheme.dark(
          primary: Colors.yellow,
          secondary: Colors.yellow,
          surface: Colors.grey.shade900, // Color for Cards, BottomNavBars, etc.
          onPrimary: Colors.black,
          onSurface: Colors.white,
        ),

        // This is the correct way to set the main background color.
        scaffoldBackgroundColor: Colors.black,

        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),

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
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/create-post': (context) => const CreatePostScreen(),
        '/classify': (context) => const ClassifyScreen(),
      },
    );
  }
}
