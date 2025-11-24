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
  // Controllers (Nullable for safety)
  AnimationController? _controller;
  AnimationController? _floatingController;
  AnimationController? _marqueeController;
  AnimationController? _rotationController;

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _subtitleFade;
  late Animation<Offset> _buttonsSlide;
  late Animation<double> _buttonsFade;

  @override
  void initState() {
    super.initState();

    // 1. Main Entrance Controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 2. Floating Background Controller
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // 3. Marquee Text Controller
    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // 4. Rotation Controller
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // --- Setup Animations ---
    // We use easeOutQuart for a smooth landing without the jitter of heavier curves
    const Curve transitionCurve = Curves.easeOutQuart;

    Animation<Offset> createSlide(double start, double end) {
      return Tween<Offset>(
        begin: const Offset(0, -1.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller!,
          curve: Interval(start, end, curve: transitionCurve),
        ),
      );
    }

    Animation<double> createFade(double start, double end) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller!,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    }

    // Define staggered timings
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller!,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _logoFade = createFade(0.0, 0.3);

    _titleSlide = createSlide(0.1, 0.6);
    _titleFade = createFade(0.1, 0.4);

    _subtitleSlide = createSlide(0.2, 0.7);
    _subtitleFade = createFade(0.2, 0.5);

    _buttonsSlide = createSlide(0.3, 0.8);
    _buttonsFade = createFade(0.3, 0.6);

    // --- FIX FOR JITTER: Delay animation start ---
    // Wait for the navigation transition (Splash -> Welcome) to finish before starting elements
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _controller?.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _floatingController?.dispose();
    _marqueeController?.dispose();
    _rotationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBlack = Colors.black;
    const Color accentYellow = Color(0xFFFFD700);
    const Color accentPurple = Color(0xFF9983F3);
    const Color accentPink = Color(0xFFFF6B6B);
    const Color accentBlue = Color(0xFF4D96FF);

    // Safety check
    if (_floatingController == null) {
      return const Scaffold(backgroundColor: Colors.white);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // --- 0. DOTTED BACKGROUND ---
          CustomPaint(size: Size.infinite, painter: DottedBackgroundPainter()),

          // --- BACKGROUND FLOATING SHAPES ---
          Positioned(
            top: 80,
            left: 30,
            child: FloatingShape(
              controller: _floatingController!,
              delay: 0.0,
              child: const Icon(Icons.star, size: 40, color: accentYellow),
            ),
          ),
          Positioned(
            top: 120,
            right: 40,
            child: FloatingShape(
              controller: _floatingController!,
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
              controller: _floatingController!,
              delay: 0.2,
              child: const Icon(Icons.add, size: 50, color: accentPurple),
            ),
          ),
          Positioned(
            bottom: 150,
            right: 30,
            child: FloatingShape(
              controller: _floatingController!,
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
              controller: _floatingController!,
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
              animation: _rotationController!,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController!.value * 2 * math.pi,
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

          // --- MAIN CONTENT ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(), // Pushes content to center vertically
                  // --- 1. APP ICON ---
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Center(
                        child: SizedBox(
                          width: 260,
                          height: 260,
                          child: Image.asset(
                            'assets/app_icon.png',
                            fit: BoxFit.contain,
                            errorBuilder:
                                (c, e, s) => const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                  size: 120,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- 2. TITLE ---
                  FadeTransition(
                    opacity: _titleFade,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: Text(
                        "KAMPUS\nKONNECT",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.archivoBlack(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: brandBlack,
                          height: 1.0,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- 3. SUBTITLE ---
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: SlideTransition(
                      position: _subtitleSlide,
                      child: Center(
                        child: Transform.rotate(
                          angle: -0.03,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: brandBlack, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: brandBlack,
                                  offset: Offset(4, 4),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Text(
                              "Your ultimate hub for campus life.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.spaceMono(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: brandBlack,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // --- 4. BUTTONS ---
                  FadeTransition(
                    opacity: _buttonsFade,
                    child: SlideTransition(
                      position: _buttonsSlide,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Column(
                            children: [
                              NeoBrutalistButton(
                                text: "GET STARTED",
                                onPressed: widget.onSignupTapped,
                                bgColor: brandBlack,
                                textColor: Colors.white,
                              ),

                              const SizedBox(height: 16),

                              NeoBrutalistButton(
                                text: "LOG IN",
                                onPressed: widget.onLoginTapped,
                                bgColor: Colors.white,
                                textColor: brandBlack,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2), // Balances bottom spacing
                ],
              ),
            ),
          ),

          // --- MARQUEE FOOTER ---
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _buttonsFade,
              child: SizedBox(
                height: 30,
                child: MarqueeText(controller: _marqueeController!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- HELPERS (Optimized for performance) ---

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
        // Use simple sine wave for smooth floating
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

class NeoBrutalistButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color bgColor;
  final Color textColor;

  const NeoBrutalistButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.bgColor,
    required this.textColor,
  });

  @override
  State<NeoBrutalistButton> createState() => _NeoBrutalistButtonState();
}

class _NeoBrutalistButtonState extends State<NeoBrutalistButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform:
            _isPressed
                ? Matrix4.translationValues(2, 2, 0)
                : Matrix4.identity(),
        decoration: BoxDecoration(
          color: widget.bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black, width: 2.5),
          boxShadow:
              _isPressed
                  ? []
                  : [
                    const BoxShadow(
                      color: Colors.black,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        width: double.infinity,
        child: Text(
          widget.text,
          textAlign: TextAlign.center,
          style: GoogleFonts.archivoBlack(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.textColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
