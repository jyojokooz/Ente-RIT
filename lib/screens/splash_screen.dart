import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;

  late Animation<double> _iconRotationAnimation;
  late Animation<double> _iconOpacityAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _fadeOutAnimation;

  @override
  void initState() {
    super.initState();

    // The main controller for the entire 4-second sequence.
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // A separate controller for the continuous, subtle pulse effect.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // --- Defining the animation phases using Intervals ---

    // Icon appears: 3D rotation, fade-in, and glow (0% to 50% of the timeline)
    _iconRotationAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    );
    _iconOpacityAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );
    _glowAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.1, 0.6, curve: Curves.easeIn),
    );

    // Text appears after the icon (40% to 75% of the timeline)
    _textAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 0.75, curve: Curves.easeOutBack),
    );

    // Final fade-out of the entire screen (85% to 100%)
    _fadeOutAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.85, 1.0, curve: Curves.easeOut),
    );

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigate();
      }
    });

    // Start the animations.
    _mainController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/auth-gate');
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- NEW VIBRANT COLOR PALETTE ---
    const Color darkBrown = Color(0xFF3E2723);
    const Color darkOrange = Color(0xFFBF360C);
    const Color primaryYellow = Color(0xFFFFC107);
    const Color lightTextColor = Color(0xFFFFF8E1);

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_mainController, _pulseController]),
        builder: (context, child) {
          return FadeTransition(
            opacity: Tween<double>(
              begin: 1.0,
              end: 0.0,
            ).animate(_fadeOutAnimation),
            child: Container(
              // --- NEW BACKGROUND GRADIENT ---
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [darkOrange, darkBrown, Colors.black],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- THE NEW ANIMATED ICON WIDGET ---
                    _buildAnimatedIcon(primaryYellow),

                    const SizedBox(height: 40),

                    // --- THE NEW ANIMATED TEXT WIDGET ---
                    _buildAnimatedText(lightTextColor),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedIcon(Color glowColor) {
    return FadeTransition(
      opacity: _iconOpacityAnimation,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          // The subtle pulsing effect
          return Transform.scale(
            scale: 1.0 + (_pulseController.value * 0.05),
            child: child,
          );
        },
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // The glowing effect that animates in
            boxShadow: [
              BoxShadow(
                color: glowColor.withAlpha(
                  (255 * _glowAnimation.value * 0.3).toInt(),
                ),
                blurRadius: 60 * _glowAnimation.value,
                spreadRadius: 5 * _glowAnimation.value,
              ),
            ],
          ),
          // The 3D rotation effect
          child: Transform(
            alignment: Alignment.center,
            transform:
                Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // Adds perspective
                  ..rotateY(
                    math.pi / 2 * (1 - _iconRotationAnimation.value),
                  ), // Rotates from edge-on
            child: Image.asset('assets/app_icon.png'),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedText(Color textColor) {
    return FadeTransition(
      opacity: _textAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(_textAnimation),
        child: Column(
          children: [
            Text(
              'KAMPUS KONNECT',
              style: GoogleFonts.orbitron(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 4.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Connect • Learn • Grow',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: textColor.withAlpha(200),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
