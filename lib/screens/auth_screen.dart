// ===============================
// FILE PATH: lib/screens/auth_screen.dart
// ===============================

import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // 0 = Login, 1 = Signup
  // We start directly at Login (Index 0) to skip the "Get Started" screen
  int _currentPageIndex = 0;
  bool _areImagesPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_areImagesPrecached) {
      precacheImage(const AssetImage('assets/app_icon.png'), context);
      precacheImage(const AssetImage('assets/google_logo.png'), context);
      _areImagesPrecached = true;
    }
  }

  void _togglePage() {
    setState(() {
      // Toggle between 0 (Login) and 1 (Signup)
      _currentPageIndex = _currentPageIndex == 0 ? 1 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _buildCurrentPage(),
      ),
    );
  }

  Widget _buildCurrentPage() {
    // We only have two states now: Login or Signup
    if (_currentPageIndex == 1) {
      return SignupPage(
        key: const ValueKey<int>(1),
        onLoginTapped: _togglePage, // Switch back to Login
        onBackTapped: _togglePage, // Switch back to Login
      );
    } else {
      return LoginPage(
        key: const ValueKey<int>(0),
        onSignupTapped: _togglePage, // Switch to Signup
        onBackTapped: () {}, // No back action on the first screen
      );
    }
  }
}
