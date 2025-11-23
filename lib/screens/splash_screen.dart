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
  late Animation<double> _loaderVisibility;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    // 1. Main Timeline Controller (8 Seconds)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );

    // 2. Binary Glitch Controller (Fast ticker)
    _binaryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    )..repeat();

    // --- INTERVAL DEFINITIONS ---

    // Phase 1: Box pops in (0% - 15%)
    _boxAppear = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.15, curve: Curves.elasticOut),
    );

    // Phase 2: Monitor slides UP (15% - 30%)
    _monitorSlide = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.15, 0.30, curve: Curves.easeInOutCubic),
    );

    // Phase 3: Monitor Wobbles/Processes (30% - 70%)
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

    // Loader Visibility (30% - 75%)
    _loaderVisibility = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        // Changed to standard threshold to avoid error
        curve: const Interval(0.30, 0.75, curve: Threshold(0.0)),
      ),
    );

    // Phase 4: Cable snakes out AFTER wobble (75% - 95%)
    _cableDraw = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.75, 0.95, curve: Curves.easeInOut),
    );

    // Phase 5: Fade out entire screen (95% - 100%)
    _fadeOut = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.95, 1.0, curve: Curves.easeOut),
    );

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigate();
      }
    });

    // Start animation
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
    const Color purpleFill = Color(0xFF9C27B0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          // Calculate visibility boolean for the loader
          final bool showLoader = _loaderVisibility.value > 0 && _cableDraw.value < 0.1;

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
                        // --- LAYER 1: SHADOW & CABLE ---
                        CustomPaint(
                          size: const Size(250, 200),
                          painter: BackgroundElementsPainter(
                            progress: _cableDraw.value,
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
                              child: const MonitorWidget(),
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

                  // --- BINARY DATA STREAM (Fixed Layout) ---
                  // We use a fixed height Container so the column doesn't shift
                  // We use Opacity to hide it instead of removing it
                  SizedBox(
                    height: 50, // Reserve fixed height space
                    child: AnimatedOpacity(
                      opacity: showLoader ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: AnimatedBuilder(
                        animation: _binaryController,
                        builder: (context, child) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // The Glitch Text
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  final randomBit = math.Random().nextBool() ? '1' : '0';
                                  // FIX: Use SizedBox here to ensure every digit takes
                                  // exact same width so the row doesn't jitter
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
                              // Static Label
                              Text(
                                "INITIALIZING SYSTEM...",
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w600
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
  const MonitorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Screen
        Container(
          width: 50,
          height: 35,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              "</>",
              style: GoogleFonts.firaCode(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black,
              ),
            ),
          ),
        ),
        // Stand neck
        Container(
          width: 4,
          height: 6,
          color: Colors.black,
        ),
        // Stand base
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

// --- 2. PAINTER FOR BACK OF BOX (Flaps and Inside) ---
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

    final Paint fillWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2 + 20;

    final topY = cy - 30;

    // Back Flap (Left)
    final Path backFlapL = Path();
    backFlapL.moveTo(cx, topY);
    backFlapL.lineTo(cx - 35, topY - 25);
    backFlapL.lineTo(cx - 40, topY + 10);
    canvas.drawPath(backFlapL, fillWhite);
    canvas.drawPath(backFlapL, stroke);

    // Back Flap (Right)
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

// --- 3. PAINTER FOR FRONT OF BOX (The purple/white cube parts) ---
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

    final Paint fillPurple = Paint()
      ..color = purpleFill
      ..style = PaintingStyle.fill;
    final Paint fillWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2 + 20;

    final double boxH = 40;
    final double boxW = 40;

    // 1. Left Face (Purple)
    final Path leftFace = Path();
    leftFace.moveTo(cx, cy);
    leftFace.lineTo(cx - boxW, cy - 15);
    leftFace.lineTo(cx - boxW, cy - 15 + boxH);
    leftFace.lineTo(cx, cy + boxH);
    leftFace.close();
    canvas.drawPath(leftFace, fillPurple);
    canvas.drawPath(leftFace, stroke);

    // 2. Right Face (White)
    final Path rightFace = Path();
    rightFace.moveTo(cx, cy);
    rightFace.lineTo(cx + boxW, cy - 15);
    rightFace.lineTo(cx + boxW, cy - 15 + boxH);
    rightFace.lineTo(cx, cy + boxH);
    rightFace.close();
    canvas.drawPath(rightFace, fillWhite);
    canvas.drawPath(rightFace, stroke);

    // 3. Front Flap (Left - Purple)
    final Path frontFlapL = Path();
    frontFlapL.moveTo(cx, cy);
    frontFlapL.lineTo(cx - boxW, cy - 15);
    frontFlapL.lineTo(cx - boxW - 15, cy);
    frontFlapL.lineTo(cx - 15, cy + 15);
    frontFlapL.close();
    canvas.drawPath(frontFlapL, fillPurple);
    canvas.drawPath(frontFlapL, stroke);

    // 4. Front Flap (Right - Purple)
    final Path frontFlapR = Path();
    frontFlapR.moveTo(cx, cy);
    frontFlapR.lineTo(cx + boxW, cy - 15);
    frontFlapR.lineTo(cx + boxW + 15, cy);
    frontFlapR.lineTo(cx + 15, cy + 15);
    frontFlapR.close();
    canvas.drawPath(frontFlapR, fillPurple);
    canvas.drawPath(frontFlapR, stroke);

    // 5. Small details on the white face
    final Paint detailPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(cx + 10, cy + 25), Offset(cx + 25, cy + 20), detailPaint);
    canvas.drawLine(
        Offset(cx + 10, cy + 32), Offset(cx + 25, cy + 27), detailPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- 4. PAINTER FOR BACKGROUND (Shadow & Animated Cable) ---
class BackgroundElementsPainter extends CustomPainter {
  final double progress;
  final double boxScale;

  BackgroundElementsPainter({required this.progress, required this.boxScale});

  @override
  void paint(Canvas canvas, Size size) {
    if (boxScale < 0.1) return;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2 + 20;

    // 1. Shadow (Black oval underneath)
    final Paint shadowPaint = Paint()..color = Colors.black;
    final Rect shadowRect = Rect.fromCenter(
        center: Offset(cx, cy + 45),
        width: 100 * boxScale,
        height: 30 * boxScale);
    canvas.drawOval(shadowRect, shadowPaint);

    // 2. Cable Animation
    if (progress > 0) {
      final Paint cablePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;

      final Paint cableOutline = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      final startX = cx + 25;
      final startY = cy + 15;

      final Path path = Path();
      path.moveTo(startX, startY);

      path.cubicTo(
          startX + 60, startY + 10, // Control 1
          startX + 20, startY + 50, // Control 2
          startX + 100, startY + 20 // End
          );

      final pathMetrics = path.computeMetrics();
      for (var metric in pathMetrics) {
        final extractPath = metric.extractPath(0.0, metric.length * progress);
        canvas.drawPath(extractPath, cableOutline);
        canvas.drawPath(extractPath, cablePaint);

        // Draw Plug Head
        if (progress > 0.1) {
          final tangent = metric.getTangentForOffset(metric.length * progress);
          if (tangent != null) {
            canvas.save();
            canvas.translate(tangent.position.dx, tangent.position.dy);
            canvas.rotate(-tangent.angle);

            final Paint plugFill = Paint()
              ..color = Colors.white
              ..style = PaintingStyle.fill;
            final Paint plugStroke = Paint()
              ..color = Colors.black
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2;

            final Rect plugRect = const Rect.fromLTWH(-2, -5, 8, 10);
            canvas.drawRect(plugRect, plugFill);
            canvas.drawRect(plugRect, plugStroke);

            canvas.restore();
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundElementsPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.boxScale != boxScale;
  }
}