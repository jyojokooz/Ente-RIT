import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import AuthGate for navigation
import 'package:my_project/auth/auth_gate.dart';

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
      // True black for dark mode, letting the Container handle light mode
      backgroundColor: isDark ? Colors.black : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient:
              isDark
                  ? null
                  : const LinearGradient(
                    colors: [Color(0xFF9983F3), Color(0xFFFF4B72)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child:
                isDark
                    // Dark Mode: Gradient Text on Black Background
                    ? ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback:
                          (bounds) => const LinearGradient(
                            colors: [Color(0xFF9983F3), Color(0xFFFF4B72)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                      child: Text(
                        "Ente RIT",
                        style: GoogleFonts.satisfy(
                          fontSize: 48, // Reduced size
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                    // Light Mode: White Text on Gradient Background
                    : Text(
                      "Ente RIT",
                      style: GoogleFonts.satisfy(
                        fontSize: 48, // Reduced size
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}
