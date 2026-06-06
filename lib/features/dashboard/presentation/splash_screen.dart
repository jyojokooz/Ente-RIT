import 'package:flutter/material.dart';

// Import AuthGate for navigation
import '../../auth/presentation/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Fast 1-second entrance animation like Instagram
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _fadeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Tiny 200ms delay after fade completes before jumping to next screen
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder:
                    (context, animation, secondaryAnimation) =>
                        const AuthGate(),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 400),
              ),
            );
          }
        });
      }
    });

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Clean solid background so the logo is perfectly visible
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: isDark ? Colors.black : Colors.white,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              Center(
                // --- DYNAMIC LOGO BASED ON THEME ---
                child: Image.asset(
                  isDark
                      ? 'assets/enterit_logo.png'
                      : 'assets/enterit_logo_light.png',
                  width: 260, // Nice large width for the splash screen
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // FIX: Return an empty box instead of text fallback to prevent flashing
                    return const SizedBox(width: 260, height: 100);
                  },
                ),
              ),
              // --- LOADING INDICATOR WITH LOGO'S PINK COLOR ---
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 60.0),
                  child: CircularProgressIndicator(
                    color: isDark ? Colors.white : const Color(0xFFFF1EDF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
