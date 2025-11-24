// ===============================
// FILE NAME: auth_screen.dart
// FILE PATH: lib/screens/auth_screen.dart
// ===============================

import 'package:flutter/material.dart';
import 'pages/welcome_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
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

  void _goToPage(int pageIndex) {
    setState(() {
      _currentPageIndex = pageIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        // Using a simple fade allows the internal staggered animations
        // of the new page to be the main visual focus.
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
    // Keys are critical for AnimatedSwitcher to detect page changes
    switch (_currentPageIndex) {
      case 1:
        return LoginPage(
          key: const ValueKey<int>(1),
          onSignupTapped: () => _goToPage(2),
          onBackTapped: () => _goToPage(0),
        );
      case 2:
        return SignupPage(
          key: const ValueKey<int>(2),
          onLoginTapped: () => _goToPage(1),
          onBackTapped: () => _goToPage(0),
        );
      case 0:
      default:
        return WelcomePage(
          key: const ValueKey<int>(0),
          onLoginTapped: () => _goToPage(1),
          onSignupTapped: () => _goToPage(2),
        );
    }
  }
}
