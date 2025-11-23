// ===============================
// FILE NAME: auth_screen.dart
// FILE PATH: lib/screens/auth_screen.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

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
  bool _reverse = false;
  bool _areImagesPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache images to prevent lag/jitter on first load
    if (!_areImagesPrecached) {
      precacheImage(const AssetImage('assets/rocket_person.png'), context);
      precacheImage(
        const AssetImage('assets/kampus_konnect_logo_wide.png'),
        context,
      );
      precacheImage(const AssetImage('assets/google_logo.png'), context);
      _areImagesPrecached = true;
    }
  }

  void _goToPage(int pageIndex) {
    setState(() {
      _reverse = pageIndex < _currentPageIndex;
      _currentPageIndex = pageIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Only show AppBar on Login/Signup to allow going back
      appBar:
          _currentPageIndex == 0
              ? null
              : AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0, // Prevents color change on scroll
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.black,
                  ),
                  onPressed: () => _goToPage(0),
                ),
              ),
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 500),
        reverse: _reverse,
        transitionBuilder: (
          Widget child,
          Animation<double> primaryAnimation,
          Animation<double> secondaryAnimation,
        ) {
          return SharedAxisTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            transitionType:
                SharedAxisTransitionType.horizontal, // Smooth side-slide
            fillColor: Colors.white,
            child: child,
          );
        },
        child: _buildCurrentPage(),
      ),
    );
  }

  Widget _buildCurrentPage() {
    // Wrap pages in Keys to ensure state is preserved/reset correctly during transition
    switch (_currentPageIndex) {
      case 1:
        return LoginPage(
          key: const ValueKey<int>(1),
          onSignupTapped: () => _goToPage(2),
        );
      case 2:
        return SignupPage(
          key: const ValueKey<int>(2),
          onLoginTapped: () => _goToPage(1),
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
