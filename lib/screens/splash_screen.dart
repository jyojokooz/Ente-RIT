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
  late Animation<double> _cableDraw;
  late Animation<double> _outletFadeIn;
  late Animation<double> _loaderVisibility;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );

    _binaryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    )..repeat();

    // --- INTERVAL DEFINITIONS ---

    // 1. Box pops in (0% - 15%)
    _boxAppear = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.15, curve: Curves.easeOutBack),
    );

    // 2. Monitor slides UP (15% - 30%)
    _monitorSlide = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.15, 0.30, curve: Curves.easeInOutCubic),
    );

    // 3. Monitor Wobbles (30% - 70%)
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
        curve: const Interval(0.30, 0.70, curve: Curves.easeInOut),
      ),
    );

    // Loading Data Visibility (30% - 75%)
    _loaderVisibility = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.30, 0.75, curve: Threshold(0.0)),
      ),
    );

    // 3.5 Outlet Fades In (65% - 75%)
    _outletFadeIn = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.65, 0.75, curve: Curves.easeIn),
    );

    // 4. Cable snakes out (75% - 95%)
    _cableDraw = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.75, 0.95, curve: Curves.easeInOut),
    );

    // 5. Fade out (96% - 100%)
    _fadeOut = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.96, 1.0, curve: Curves.easeOut),
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
          final bool showLoader =
              _loaderVisibility.value > 0 && _cableDraw.value < 0.1;

          // Determine screen color based on connection status
          final bool isConnected = _cableDraw.value > 0.99;
          // CHANGED: Uses purpleFill instead of Yellow
          final Color screenColor = isConnected ? purpleFill : Colors.white;

          return FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeOut),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- THE ANIMATED ICON STACK ---
                  SizedBox(
                    width: 320,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // --- LAYER 1: SHADOW, CABLE & OUTLET ---
                        CustomPaint(
                          size: const Size(320, 200),
                          painter: BackgroundElementsPainter(
                            progress: _cableDraw.value,
                            boxScale: _boxAppear.value,
                            outletOpacity: _outletFadeIn.value,
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
                      duration: const Duration(milliseconds: 300),
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
    // Check if screen is active (not white) to apply text color change
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
            // Purple Glow when active
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: screenColor.withOpacity(0.6),
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
                // Make text White if screen is Purple, else Black
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

// --- 4. PAINTER FOR BACKGROUND (Shadow, Cable & Outlet) ---
class BackgroundElementsPainter extends CustomPainter {
  final double progress;
  final double boxScale;
  final double outletOpacity;

  BackgroundElementsPainter({
    required this.progress,
    required this.boxScale,
    required this.outletOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (boxScale <= 0) return;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2 + 20;

    // 1. Shadow
    final Paint shadowPaint = Paint()..color = Colors.black;
    final Rect shadowRect = Rect.fromCenter(
      center: Offset(cx, cy + 45),
      width: 100 * boxScale,
      height: 30 * boxScale,
    );
    canvas.drawOval(shadowRect, shadowPaint);

    // Coordinates for Connection
    final outletX = cx + 130.0;
    final outletY = cy + 20.0;

    // 2. Wall Outlet
    if (outletOpacity > 0) {
      final Paint outletStroke =
          Paint()
            ..color = Colors.black.withOpacity(outletOpacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5;
      final Paint outletFill =
          Paint()
            ..color = Colors.white.withOpacity(outletOpacity)
            ..style = PaintingStyle.fill;

      final Rect outletRect = Rect.fromCenter(
        center: Offset(outletX, outletY),
        width: 22,
        height: 28,
      );

      canvas.drawRect(outletRect, outletFill);
      canvas.drawRect(outletRect, outletStroke);

      final Paint holePaint =
          Paint()..color = Colors.black.withOpacity(outletOpacity);
      canvas.drawCircle(Offset(outletX, outletY - 6), 2.5, holePaint);
      canvas.drawCircle(Offset(outletX, outletY + 6), 2.5, holePaint);
    }

    // 3. Cable Animation
    if (progress > 0) {
      final Paint cablePaint =
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8
            ..strokeCap = StrokeCap.round;

      final Paint cableOutline =
          Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = 12
            ..strokeCap = StrokeCap.round;

      final startX = cx + 25;
      final startY = cy + 15;

      final endX = outletX - 20;
      final endY = outletY;

      final Path path = Path();
      path.moveTo(startX, startY);

      path.cubicTo(
        startX + 60,
        startY + 10, // Control 1
        startX + 40,
        endY, // Control 2
        endX,
        endY, // End
      );

      final pathMetrics = path.computeMetrics();
      for (var metric in pathMetrics) {
        final extractPath = metric.extractPath(0.0, metric.length * progress);
        canvas.drawPath(extractPath, cableOutline);
        canvas.drawPath(extractPath, cablePaint);

        // Draw Plug Head
        if (progress > 0.05) {
          final tangent = metric.getTangentForOffset(metric.length * progress);
          if (tangent != null) {
            canvas.save();
            canvas.translate(tangent.position.dx, tangent.position.dy);
            canvas.rotate(-tangent.angle);

            final Paint plugFill =
                Paint()
                  ..color = Colors.white
                  ..style = PaintingStyle.fill;
            final Paint plugStroke =
                Paint()
                  ..color = Colors.black
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2.5;
            final Paint prongPaint =
                Paint()
                  ..color = Colors.black
                  ..strokeWidth = 3;

            // Prongs
            canvas.drawLine(
              const Offset(7, -4),
              const Offset(15, -4),
              prongPaint,
            );
            canvas.drawLine(
              const Offset(7, 4),
              const Offset(15, 4),
              prongPaint,
            );

            // Plug Body
            final RRect plugBody = RRect.fromRectAndRadius(
              const Rect.fromLTWH(-7, -8, 14, 16),
              const Radius.circular(3),
            );

            canvas.drawRRect(plugBody, plugFill);
            canvas.drawRRect(plugBody, plugStroke);

            canvas.restore();
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundElementsPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.boxScale != boxScale ||
        oldDelegate.outletOpacity != outletOpacity;
  }
}
