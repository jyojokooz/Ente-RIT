// = "=============================="
// FILE NAME: splash_screen.dart
// FILE PATH: lib/screens/splash_screen.dart
// "=============================="

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
  late AnimationController _binaryController;

  late Animation<double> _boxAppear;
  late Animation<double> _monitorSlide;
  late Animation<double> _monitorWobble;
  late Animation<double> _loaderVisibility;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _binaryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    )..repeat();

    _boxAppear = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.20, curve: Curves.easeOutBack),
    );
    _monitorSlide = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.20, 0.40, curve: Curves.easeInOutCubic),
    );
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
    _loaderVisibility = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.40, 0.80, curve: Threshold(0.0)),
      ),
    );
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
    _binaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color purpleFill = Color(0xFF9983F3);

    return Scaffold(
      backgroundColor: Colors.white, // White background
      body: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          final bool showLoader = _loaderVisibility.value > 0;
          final bool isSystemReady = _mainController.value > 0.8;
          final Color screenColor = isSystemReady ? purpleFill : Colors.white;

          return FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeOut),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(250, 200),
                          painter: ShadowPainter(boxScale: _boxAppear.value),
                        ),
                        Transform.scale(
                          scale: _boxAppear.value,
                          child: CustomPaint(
                            size: const Size(120, 120),
                            painter: BoxBackPainter(),
                          ),
                        ),
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
                                  color: Colors.grey[700],
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

// --- HELPER WIDGETS AND PAINTERS (Colors adjusted for white background) ---

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
  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round;
    final Paint fill =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2 + 20;
    final topY = cy - 30;

    final Path backFlapL = Path();
    backFlapL.moveTo(cx, topY);
    backFlapL.lineTo(cx - 35, topY - 25);
    backFlapL.lineTo(cx - 40, topY + 10);
    canvas.drawPath(backFlapL, fill);
    canvas.drawPath(backFlapL, stroke);

    final Path backFlapR = Path();
    backFlapR.moveTo(cx, topY);
    backFlapR.lineTo(cx + 35, topY - 25);
    backFlapR.lineTo(cx + 40, topY + 10);
    canvas.drawPath(backFlapR, fill);
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
    final Paint fillSide =
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
    canvas.drawPath(rightFace, fillSide);
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
    final Paint shadowPaint = Paint()..color = Colors.black.withAlpha(80);
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
