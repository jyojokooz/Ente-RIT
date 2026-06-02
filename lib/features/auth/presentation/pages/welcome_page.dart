import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomePage extends StatefulWidget {
  final VoidCallback onLoginTapped;
  final VoidCallback onSignupTapped;

  const WelcomePage({
    super.key,
    required this.onLoginTapped,
    required this.onSignupTapped,
  });

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget titleText = Text(
      "Ente RIT",
      style: GoogleFonts.satisfy(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );

    // Apply gradient mask to text only in dark mode
    if (isDark) {
      titleText = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback:
            (bounds) => const LinearGradient(
              colors: [Color(0xFF9983F3), Color(0xFFFF4B72)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
        child: titleText,
      );
    }

    return Scaffold(
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Centered Text Logo
              Center(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: titleText,
                ),
              ),

              // Bottom Buttons
              Positioned(
                bottom: 40,
                left: 24,
                right: 24,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: widget.onSignupTapped,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          "Get Started",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account?",
                            style: GoogleFonts.poppins(
                              color:
                                  isDark
                                      ? Colors.white70
                                      : Colors.white.withAlpha(200),
                            ),
                          ),
                          TextButton(
                            onPressed: widget.onLoginTapped,
                            child: Text(
                              "Log In",
                              style: GoogleFonts.poppins(
                                color:
                                    isDark
                                        ? const Color(0xFF9983F3)
                                        : Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor:
                                    isDark
                                        ? const Color(0xFF9983F3)
                                        : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
