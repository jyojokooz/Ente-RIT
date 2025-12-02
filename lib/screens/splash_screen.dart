// ===============================
// FILE NAME: splash_screen.dart
// FILE PATH: lib/screens/splash_screen.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

// Import AuthGate for navigation
import 'package:my_project/auth/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _loopingController;
  late AnimationController _binaryController;

  late Animation<double> _iconFade, _textFade, _accentFade, _screenFadeOut;
  late Animation<Offset> _iconSlide;
  late Animation<double> _textScale, _accentScale;

  @override
  void initState() {
    super.initState();

    // 1. Entrance Sequence (3.5 seconds)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    // 2. Looping (Bobbing)
    _loopingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    // 3. Binary Loader (Twitching)
    _binaryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    )..repeat();

    // --- ANIMATION DEFINITIONS (Copied from WelcomePage) ---

    // Icon slides to the top-right-ish area
    _iconSlide = Tween<Offset>(
      begin: const Offset(0.5, -2.0),
      end: const Offset(0.5, -0.6), // Matches Welcome Page Position
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _textScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeIn),
      ),
    );

    _accentScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.9, curve: Curves.elasticOut),
      ),
    );

    _accentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
      ),
    );

    // Fade out purple background to white at the end
    _screenFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.85, 1.0, curve: Curves.easeOut),
      ),
    );

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigate();
      }
    });

    _mainController.forward();
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => const AuthGate(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _loopingController.dispose();
    _binaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandPurple = Color(0xFF9983F3);
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Purple Background & Content (Fades out at end)
          FadeTransition(
            opacity: _screenFadeOut,
            child: Container(
              color: brandPurple,
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // --- SPARKLES (Exact coordinates from WelcomePage) ---
                  Sparkle(
                    animation: _loopingController,
                    top: screenSize.height * 0.1,
                    left: screenSize.width * 0.15,
                    delay: 0.0,
                  ),
                  Sparkle(
                    animation: _loopingController,
                    top: screenSize.height * 0.2,
                    right: screenSize.width * 0.1,
                    delay: 0.3,
                  ),
                  Sparkle(
                    animation: _loopingController,
                    top: screenSize.height * 0.6,
                    right: screenSize.width * 0.2,
                    delay: 0.5,
                  ),
                  Sparkle(
                    animation: _loopingController,
                    bottom: screenSize.height * 0.15,
                    left: screenSize.width * 0.25,
                    delay: 0.8,
                  ),
                  Sparkle(
                    animation: _loopingController,
                    bottom: screenSize.height * 0.35,
                    left: screenSize.width * 0.1,
                    delay: 0.4,
                  ),
                  Sparkle(
                    animation: _loopingController,
                    top: screenSize.height * 0.8,
                    right: screenSize.width * 0.1,
                    delay: 0.7,
                  ),

                  // --- ICON WITH HAT ---
                  AnimatedBuilder(
                    animation: _loopingController,
                    builder: (context, child) {
                      final double offset =
                          math.sin(_loopingController.value * 2 * math.pi) * 8;
                      return Transform.translate(
                        offset: Offset(0, offset),
                        child: child,
                      );
                    },
                    child: FadeTransition(
                      opacity: _iconFade,
                      child: SlideTransition(
                        position: _iconSlide, // Moves icon to top-right
                        child: Transform.rotate(
                          angle: 0.2, // Tilted
                          child: Image.asset(
                            'assets/icon_with_cap.png',
                            height: 200, // Exact size
                            errorBuilder:
                                (c, e, s) => const Icon(
                                  Icons.school,
                                  size: 120,
                                  color: Colors.white,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- ENTE RIT TEXT & DECORATIONS ---
                  Center(
                    child: AnimatedBuilder(
                      animation: _loopingController,
                      builder: (context, child) {
                        final double offset =
                            math.sin(
                              (_loopingController.value * 2 * math.pi) + 1,
                            ) *
                            -8;
                        return Transform.translate(
                          offset: Offset(0, offset),
                          child: child,
                        );
                      },
                      child: FadeTransition(
                        opacity: _textFade,
                        child: ScaleTransition(
                          scale: _textScale,
                          child: SizedBox(
                            width: 300,
                            height: 300,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Main Text Image
                                Image.asset(
                                  'assets/ente_rit.png',
                                  width: 220, // Exact width
                                  errorBuilder:
                                      (c, e, s) => Text(
                                        "Ente RIT",
                                        style: GoogleFonts.poppins(
                                          fontSize: 50,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                ),

                                // Droplets and Lines
                                FadeTransition(
                                  opacity: _accentFade,
                                  child: ScaleTransition(
                                    scale: _accentScale,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          top: 20,
                                          left: 60,
                                          child: CustomPaint(
                                            painter: DropletsPainter(),
                                            size: const Size(50, 30),
                                          ),
                                        ),
                                        Positioned(
                                          top: 100,
                                          right: 30,
                                          child: CustomPaint(
                                            painter: LinesPainter(),
                                            size: const Size(30, 30),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- BINARY LOADER (Bottom Center) ---
                  Positioned(
                    bottom: 60,
                    child: AnimatedBuilder(
                      animation: _binaryController,
                      builder: (context, child) {
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                final randomBit =
                                    math.Random().nextBool() ? '1' : '0';
                                return SizedBox(
                                  width: 20,
                                  child: Text(
                                    randomBit,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.firaCode(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "LOADING SYSTEM...",
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                letterSpacing: 1.5,
                                color: Colors.white.withOpacity(0.6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- PAINTERS (Copied directly from WelcomePage) ---

class Sparkle extends StatelessWidget {
  final Animation<double> animation;
  final double? top, bottom, left, right;
  final double delay;

  const Sparkle({
    super.key,
    required this.animation,
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.delay = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final double opacity = (0.5 +
                  0.5 *
                      math.sin(
                        (animation.value * 2 * math.pi) + (delay * math.pi),
                      ))
              .clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity,
            child: CustomPaint(
              painter: SparklePainter(),
              size: const Size(20, 20),
            ),
          );
        },
      ),
    );
  }
}

class SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final center = size.center(Offset.zero);
    final path = Path();
    path.moveTo(center.dx, center.dy - size.height / 2);
    path.lineTo(center.dx + size.width / 4, center.dy - size.height / 4);
    path.lineTo(center.dx + size.width / 2, center.dy);
    path.lineTo(center.dx + size.width / 4, center.dy + size.height / 4);
    path.lineTo(center.dx, center.dy + size.height / 2);
    path.lineTo(center.dx - size.width / 4, center.dy + size.height / 4);
    path.lineTo(center.dx - size.width / 2, center.dy);
    path.lineTo(center.dx - size.width / 4, center.dy - size.height / 4);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DropletsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.7), 8, paint);
    final path = Path();
    path.moveTo(size.width * 0.5 - 8, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.5,
      0,
      size.width * 0.5 + 8,
      size.height * 0.7,
    );
    canvas.drawPath(path, paint);
    canvas.save();
    canvas.translate(-20, 5);
    canvas.rotate(-0.5);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.7), 5, paint);
    final path2 = Path();
    path2.moveTo(size.width * 0.5 - 5, size.height * 0.7);
    path2.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.2,
      size.width * 0.5 + 5,
      size.height * 0.7,
    );
    canvas.drawPath(path2, paint);
    canvas.restore();
    canvas.save();
    canvas.translate(20, 5);
    canvas.rotate(0.5);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.7), 5, paint);
    canvas.drawPath(path2, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height * 0.2), Offset(size.width, 0), paint);
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.8),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
