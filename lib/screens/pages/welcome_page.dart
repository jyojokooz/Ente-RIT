// ===============================
// FILE NAME: welcome_page.dart
// FILE PATH: lib/screens/pages/welcome_page.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

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
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _loopingController;

  late Animation<double> _iconFade, _textFade, _buttonFade, _accentFade;
  late Animation<Offset> _iconSlide;
  late Animation<double> _textScale, _accentScale;
  late Animation<Offset> _buttonsSlide;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _loopingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _iconSlide = Tween<Offset>(
      begin: const Offset(0.5, -2.0),
      end: const Offset(0.5, -0.6),
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _textScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
      ),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeIn),
      ),
    );

    _accentScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.5, 0.9, curve: Curves.elasticOut),
      ),
    );
    _accentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
      ),
    );

    _buttonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );
    _buttonsSlide = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _loopingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandPurple = Color(0xFF9983F3);
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: brandPurple,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Elements
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

          // --- MAIN CONTENT ---
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
                position: _iconSlide,
                child: Transform.rotate(
                  angle: 0.2,
                  child: Image.asset(
                    'assets/icon_with_cap.png',
                    height: 200,
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

          Center(
            child: AnimatedBuilder(
              animation: _loopingController,
              builder: (context, child) {
                final double offset =
                    math.sin((_loopingController.value * 2 * math.pi) + 1) * -8;
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
                        // FIX: Reduced width from 250 to 220
                        Image.asset(
                          'assets/ente_rit.png',
                          width: 220,
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

          // --- BUTTONS ---
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: FadeTransition(
              opacity: _buttonFade,
              child: SlideTransition(
                position: _buttonsSlide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: widget.onSignupTapped,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
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
                            color: Colors.white.withAlpha(200),
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onLoginTapped,
                          child: Text(
                            "Log In",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- HELPER WIDGETS AND PAINTERS ---
class Sparkle extends StatelessWidget {
  final Animation<double> animation;
  final double? top, bottom, left, right;
  final double delay;

  Sparkle({
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
