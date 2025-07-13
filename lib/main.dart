import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// Assuming all your UI files are in these subfolders
import 'package:my_project/screens/splash_screen.dart';
import 'package:my_project/screens/welcome_screen.dart';
import 'package:my_project/auth/signup_screen.dart';
import 'package:my_project/auth/login_screen.dart';
import 'package:my_project/auth/forgot_password_screen.dart';
import 'package:my_project/screens/home_screen.dart';
import 'package:my_project/screens/create_post_screen.dart';

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
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark().copyWith(
          secondary: Colors.yellow, // Example accent color
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/create-post':
            (context) => const CreatePostScreen(), // Keep this route
      },
    );
  }
}
