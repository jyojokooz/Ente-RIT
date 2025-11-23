// ===============================
// FILE NAME: splash_screen.dart
// FILE PATH: lib/screens/splash_screen.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _binaryController;

  // Animation Stages
  late Animation<double> _boxAppear;
  late Animation<double> _monitorSlide;
  late Animation<double> _monitorWobble;
  late Animation<double> _loaderVisibility;
  late Animation<double> _fadeOut;

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

    // --- INTERVAL DEFINITIONS ---

    // 1. Box pops in
    _boxAppear = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.20, curve: Curves.easeOutBack),
    );

    // 2. Monitor slides UP
    _monitorSlide = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.20, 0.40, curve: Curves.easeInOutCubic),
    );

    // 3. Monitor Wobbles/Processing
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

    // 4. Fade out
    _fadeOut = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.90, 1.0, curve: Curves.easeOut),
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
    Navigator.pushReplacementNamed(context, '/auth-gate');
  }

  @override
  void dispose() {
    _mainController.dispose();
    _binaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color purpleFill = Color(0xFF9983F3);

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          // Show loader only during the specific interval
          final bool showLoader = _loaderVisibility.value > 0;
          
          // Turn screen purple after wobble finishes
          final bool isSystemReady = _mainController.value > 0.8;
          final Color screenColor = isSystemReady ? purpleFill : Colors.white;

          return FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeOut),
            child: Center(
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
                        // --- LAYER 1: SHADOW ---
                        CustomPaint(
                          size: const Size(250, 200),
                          painter: ShadowPainter(
                            boxScale: _boxAppear.value,
                          ),
                        ),

                        // --- LAYER 2: BACK OF BOX (Inside) ---
                        Transform.scale(
                          scale: _boxAppear.value,
                          child: CustomPaint(
                            size: const Size(120, 120),
                            painter: BoxBackPainter(purpleFill: purpleFill),
                          ),
                        ),

                        // --- LAYER 3: THE MONITOR ---
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

                        // --- LAYER 4: FRONT OF BOX ---
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
            ),
          );
        },
      ),
    );
  }
}

// --- 1. THE MONITOR ICON WIDGET ---
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
            // --- FIX: Replaced withOpacity(0.6) with withAlpha(153) ---
            boxShadow: isActive
              ? [
                  BoxShadow(
                    color: screenColor.withAlpha(153), // 0.6 * 255 = 153
                    blurRadius: 15,
                    spreadRadius: 2
                  )
                ] 
              : [
                  const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
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

// --- 2. PAINTER FOR BACK OF BOX ---
class BoxBackPainter extends CustomPainter {
  final Color purpleFill;
  BoxBackPainter({required this.purpleFill});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    final Paint fillWhite = Paint()..color = Colors.white..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2 + 20;
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

// --- 3. PAINTER FOR FRONT OF BOX ---
class BoxFrontPainter extends CustomPainter {
  final Color purpleFill;
  BoxFrontPainter({required this.purpleFill});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    final Paint fillPurple = Paint()..color = purpleFill..style = PaintingStyle.fill;
    final Paint fillWhite = Paint()..color = Colors.white..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2 + 20;
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

    final Paint detailPaint = Paint()..color = Colors.black..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx + 10, cy + 25), Offset(cx + 25, cy + 20), detailPaint);
    canvas.drawLine(Offset(cx + 10, cy + 32), Offset(cx + 25, cy + 27), detailPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- 4. PAINTER FOR SHADOW ---
class ShadowPainter extends CustomPainter {
  final double boxScale;

  ShadowPainter({required this.boxScale});

  @override
  void paint(Canvas canvas, Size size) {
    if (boxScale <= 0) return;

    final cx = size.width / 2;
    final cy = size.height / 2 + 20;

    // --- FIX: Used withAlpha for proper transparency on shadow ---
    // 50 alpha is roughly 20% opacity
    final Paint shadowPaint = Paint()..color = Colors.black.withAlpha(50);
    
    final Rect shadowRect = Rect.fromCenter(
        center: Offset(cx, cy + 45),
        width: 100 * boxScale,
        height: 30 * boxScale);
    canvas.drawOval(shadowRect, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant ShadowPainter oldDelegate) {
    return oldDelegate.boxScale != boxScale;
  }
}