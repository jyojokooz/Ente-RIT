// ===============================
// FILE NAME: splash_screen.dart
// FILE PATH: lib/screens/splash_screen.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

// Import AuthGate for the smooth transition
import '../auth/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Main Animation Controllers
  late AnimationController _mainController;
  late AnimationController _binaryController;

  // Background Animation Controllers
  late AnimationController _floatingController;
  late AnimationController _marqueeController;
  late AnimationController _rotationController;

  // Animation Stages
  late Animation<double> _boxAppear;
  late Animation<double> _monitorSlide;
  late Animation<double> _monitorWobble;
  late Animation<double> _loaderVisibility;
  // Removed _fadeOut to prevent vignette effect

  @override
  void initState() {
    super.initState();

    // 1. Main Timeline Controller (3.5 Seconds)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    // 2. Binary Glitch Controller
    _binaryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    )..repeat();

    // 3. Floating Background Controller
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // 4. Marquee Text Controller
    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // 5. Rotation Controller
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // --- INTERVAL DEFINITIONS ---

    // 1. Box pops in (0% - 20%)
    _boxAppear = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.20, curve: Curves.easeOutBack),
    );

    // 2. Monitor slides UP (20% - 40%)
    _monitorSlide = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.20, 0.40, curve: Curves.easeInOutCubic),
    );

    // 3. Monitor Wobbles/Processing (40% - 80%)
    _monitorWobble = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.05), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.05), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.05), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.05), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.05), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.40, 0.80, curve: Curves.easeInOut),
      ),
    );

    // Loader Visibility
    _loaderVisibility = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.40, 0.80, curve: Threshold(0.0)),
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

    // FIX: Custom PageRouteBuilder for ultra-smooth cross-fade
    // instead of standard pushReplacementNamed which can be jarring.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => const AuthGate(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Smooth Fade Transition
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(
          milliseconds: 800,
        ), // Slow, smooth fade
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _binaryController.dispose();
    _floatingController.dispose();
    _marqueeController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color purpleFill = Color(0xFF9983F3);
    const Color brandBlack = Colors.black;
    const Color accentYellow = Color(0xFFFFD700);
    const Color accentPurple = Color(0xFF9983F3);
    const Color accentPink = Color(0xFFFF6B6B);
    const Color accentBlue = Color(0xFF4D96FF);

    return Scaffold(
      backgroundColor: Colors.white,
      // Removed FadeTransition here to prevent the "vignette" effect
      body: Stack(
        children: [
          // --- 0. DOTTED BACKGROUND PATTERN ---
          CustomPaint(size: Size.infinite, painter: DottedBackgroundPainter()),

          // --- BACKGROUND FLOATING SHAPES ---
          Positioned(
            top: 80,
            left: 30,
            child: FloatingShape(
              controller: _floatingController,
              delay: 0.0,
              child: const Icon(Icons.star, size: 40, color: accentYellow),
            ),
          ),
          Positioned(
            top: 120,
            right: 40,
            child: FloatingShape(
              controller: _floatingController,
              delay: 0.5,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accentPink, width: 3),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: 40,
            child: FloatingShape(
              controller: _floatingController,
              delay: 0.2,
              child: const Icon(Icons.add, size: 50, color: accentPurple),
            ),
          ),
          Positioned(
            bottom: 150,
            right: 30,
            child: FloatingShape(
              controller: _floatingController,
              delay: 0.7,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  border: Border.all(color: brandBlack, width: 3),
                ),
              ),
            ),
          ),
          Positioned(
            top: 300,
            right: -20,
            child: FloatingShape(
              controller: _floatingController,
              delay: 0.9,
              child: Transform.rotate(
                angle: -0.2,
                child: Container(
                  width: 80,
                  height: 30,
                  decoration: BoxDecoration(
                    color: accentBlue,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: brandBlack, width: 2),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 180,
            left: 80,
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * math.pi,
                  child: const Icon(
                    Icons.verified_outlined,
                    size: 35,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 100,
            left: -10,
            child: CustomPaint(
              size: const Size(100, 50),
              painter: SquigglyLinePainter(color: accentPink),
            ),
          ),

          // --- MAIN ANIMATION ---
          AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              final bool showLoader = _loaderVisibility.value > 0;
              // Trigger "Connected" state when wobble is done
              final bool isSystemReady = _mainController.value > 0.8;
              final Color screenColor =
                  isSystemReady ? purpleFill : Colors.white;

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- THE ANIMATED ICON STACK ---
                    SizedBox(
                      width: 250,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // LAYER 1: SHADOW
                          CustomPaint(
                            size: const Size(250, 200),
                            painter: ShadowPainter(boxScale: _boxAppear.value),
                          ),

                          // LAYER 2: BACK OF BOX
                          Transform.scale(
                            scale: _boxAppear.value,
                            child: CustomPaint(
                              size: const Size(120, 120),
                              painter: BoxBackPainter(purpleFill: purpleFill),
                            ),
                          ),

                          // LAYER 3: MONITOR
                          Positioned(
                            top: 40 + (1 - _monitorSlide.value) * 60,
                            child: Transform.scale(
                              scale: _boxAppear.value,
                              child: Transform.rotate(
                                angle: _monitorWobble.value,
                                child: MonitorWidget(screenColor: screenColor),
                              ),
                            ),
                          ),

                          // LAYER 4: FRONT OF BOX
                          Transform.scale(
                            scale: _boxAppear.value,
                            child: CustomPaint(
                              size: const Size(120, 120),
                              painter: BoxFrontPainter(purpleFill: purpleFill),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),

                    // --- BINARY DATA STREAM ---
                    SizedBox(
                      height: 50,
                      child: AnimatedOpacity(
                        opacity: showLoader ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: AnimatedBuilder(
                          animation: _binaryController,
                          builder: (context, child) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                          color: purpleFill,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "INITIALIZING SYSTEM...",
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    letterSpacing: 1.5,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // --- MARQUEE FOOTER ---
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 30,
              child: MarqueeText(controller: _marqueeController),
            ),
          ),
        ],
      ),
    );
  }
}

// --- REUSABLE HELPERS ---

class FloatingShape extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final Widget child;

  const FloatingShape({
    super.key,
    required this.controller,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, childWidget) {
        final double offset =
            math.sin((controller.value * 2 * math.pi) + delay) * 10;
        return Transform.translate(
          offset: Offset(0, offset),
          child: childWidget,
        );
      },
      child: child,
    );
  }
}

class MarqueeText extends StatelessWidget {
  final AnimationController controller;
  const MarqueeText({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double slide = -controller.value * 200;
        return Stack(
          children: [
            Transform.translate(
              offset: Offset(slide, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: List.generate(10, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "CONNECT • LEARN • GROW • ",
                        style: GoogleFonts.archivoBlack(
                          fontSize: 14,
                          color: Colors.grey.shade300,
                          letterSpacing: 2,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DottedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.shade200
          ..strokeWidth = 2
          ..style = PaintingStyle.fill;

    const double step = 40;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        if (x % (step * 2) == 0 && y % (step * 2) == 0) {
          canvas.drawCircle(Offset(x, y), 1.5, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SquigglyLinePainter extends CustomPainter {
  final Color color;
  SquigglyLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height / 2);

    double x = 0;
    while (x < size.width) {
      path.relativeQuadraticBezierTo(10, -20, 20, 0);
      path.relativeQuadraticBezierTo(10, 20, 20, 0);
      x += 40;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- PAINTERS FOR BOX ANIMATION ---

class MonitorWidget extends StatelessWidget {
  final Color screenColor;

  const MonitorWidget({super.key, required this.screenColor});

  @override
  Widget build(BuildContext context) {
    final bool isActive = screenColor != Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 50,
          height: 35,
          decoration: BoxDecoration(
            color: screenColor,
            border: Border.all(color: Colors.black, width: 2.5),
            borderRadius: BorderRadius.circular(4),
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: screenColor.withAlpha(153),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ]
                    : [
                      const BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
          ),
          child: Center(
            child: Text(
              "</>",
              style: GoogleFonts.firaCode(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isActive ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
        Container(width: 4, height: 6, color: Colors.black),
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class BoxBackPainter extends CustomPainter {
  final Color purpleFill;
  BoxBackPainter({required this.purpleFill});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round;
    final Paint fillWhite =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    final w = size.width;
    final cx = w / 2;
    final cy = size.height / 2 + 20;
    final topY = cy - 30;

    final Path backFlapL = Path();
    backFlapL.moveTo(cx, topY);
    backFlapL.lineTo(cx - 35, topY - 25);
    backFlapL.lineTo(cx - 40, topY + 10);
    canvas.drawPath(backFlapL, fillWhite);
    canvas.drawPath(backFlapL, stroke);

    final Path backFlapR = Path();
    backFlapR.moveTo(cx, topY);
    backFlapR.lineTo(cx + 35, topY - 25);
    backFlapR.lineTo(cx + 40, topY + 10);
    canvas.drawPath(backFlapR, fillWhite);
    canvas.drawPath(backFlapR, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BoxFrontPainter extends CustomPainter {
  final Color purpleFill;
  BoxFrontPainter({required this.purpleFill});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round;
    final Paint fillPurple =
        Paint()
          ..color = purpleFill
          ..style = PaintingStyle.fill;
    final Paint fillWhite =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2 + 20;
    final double boxH = 40;
    final double boxW = 40;

    final Path leftFace = Path();
    leftFace.moveTo(cx, cy);
    leftFace.lineTo(cx - boxW, cy - 15);
    leftFace.lineTo(cx - boxW, cy - 15 + boxH);
    leftFace.lineTo(cx, cy + boxH);
    leftFace.close();
    canvas.drawPath(leftFace, fillPurple);
    canvas.drawPath(leftFace, stroke);

    final Path rightFace = Path();
    rightFace.moveTo(cx, cy);
    rightFace.lineTo(cx + boxW, cy - 15);
    rightFace.lineTo(cx + boxW, cy - 15 + boxH);
    rightFace.lineTo(cx, cy + boxH);
    rightFace.close();
    canvas.drawPath(rightFace, fillWhite);
    canvas.drawPath(rightFace, stroke);

    final Path frontFlapL = Path();
    frontFlapL.moveTo(cx, cy);
    frontFlapL.lineTo(cx - boxW, cy - 15);
    frontFlapL.lineTo(cx - boxW - 15, cy);
    frontFlapL.lineTo(cx - 15, cy + 15);
    frontFlapL.close();
    canvas.drawPath(frontFlapL, fillPurple);
    canvas.drawPath(frontFlapL, stroke);

    final Path frontFlapR = Path();
    frontFlapR.moveTo(cx, cy);
    frontFlapR.lineTo(cx + boxW, cy - 15);
    frontFlapR.lineTo(cx + boxW + 15, cy);
    frontFlapR.lineTo(cx + 15, cy + 15);
    frontFlapR.close();
    canvas.drawPath(frontFlapR, fillPurple);
    canvas.drawPath(frontFlapR, stroke);

    final Paint detailPaint =
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx + 10, cy + 25),
      Offset(cx + 25, cy + 20),
      detailPaint,
    );
    canvas.drawLine(
      Offset(cx + 10, cy + 32),
      Offset(cx + 25, cy + 27),
      detailPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ShadowPainter extends CustomPainter {
  final double boxScale;
  ShadowPainter({required this.boxScale});

  @override
  void paint(Canvas canvas, Size size) {
    if (boxScale <= 0) return;
    final cx = size.width / 2;
    final cy = size.height / 2 + 20;
    final Paint shadowPaint = Paint()..color = Colors.black.withAlpha(50);
    final Rect shadowRect = Rect.fromCenter(
      center: Offset(cx, cy + 45),
      width: 100 * boxScale,
      height: 30 * boxScale,
    );
    canvas.drawOval(shadowRect, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant ShadowPainter oldDelegate) =>
      oldDelegate.boxScale != boxScale;
}
