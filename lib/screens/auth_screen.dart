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
  bool _areImagesPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_areImagesPrecached) {
      precacheImage(const AssetImage('assets/person_and_dog.png'), context);
      precacheImage(const AssetImage('assets/rocket_person.png'), context);
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
      // --- THIS IS THE ONLY LINE YOU NEED TO CHANGE ---
      // This single line explicitly sets the background for Welcome, Login,
      // and Signup pages to black, overriding any theme color.
      backgroundColor: Colors.black,

      appBar:
          _currentPageIndex == 0
              ? null
              : AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => _goToPage(0),
                ),
              ),
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 600),
        reverse: _currentPageIndex == 0,
        transitionBuilder: (
          Widget child,
          Animation<double> primaryAnimation,
          Animation<double> secondaryAnimation,
        ) {
          return FadeThroughTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: _buildCurrentPage(),
      ),
    );
  }

  Widget _buildCurrentPage() {
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
