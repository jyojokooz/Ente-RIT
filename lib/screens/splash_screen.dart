// ignore_for_file: deprecated_member_use

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
  late AnimationController _confettiController;

  late Animation<double> _iconRotationAnimation;
  late Animation<double> _iconOpacityAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _fadeOutAnimation;
  late Animation<double> _iconSqueezeAnimation;
  late Animation<double> _capsAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

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

    _iconSqueezeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 40),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.65, curve: Curves.easeInOut),
      ),
    );

    _capsAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
    );

    _textAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 0.75, curve: Curves.easeOutBack),
    );

    _fadeOutAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.85, 1.0, curve: Curves.easeOut),
    );

    _mainController.addListener(() {
      if (_mainController.value > 0.5 && !_confettiController.isAnimating) {
        _confettiController.forward(from: 0.0);
      }
    });

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigate();
      }
    });

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
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBrown = Color(0xFF3E2723);
    const Color darkOrange = Color(0xFFBF360C);
    const Color primaryYellow = Color(0xFFFFC107);
    const Color lightTextColor = Color(0xFFFFF8E1);

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _mainController,
          _pulseController,
          _confettiController,
        ]),
        builder: (context, child) {
          return FadeTransition(
            opacity: Tween<double>(
              begin: 1.0,
              end: 0.0,
            ).animate(_fadeOutAnimation),
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [darkOrange, darkBrown, Colors.black],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      painter: FlyingCapsPainter(
                        animationValue: _capsAnimation.value,
                        color: primaryYellow,
                      ),
                      child: const SizedBox.expand(),
                    ),
                    CustomPaint(
                      painter: ConfettiPainter(
                        animationValue: _confettiController.value,
                        colors: [
                          primaryYellow,
                          Colors.red.shade400,
                          Colors.white,
                        ],
                      ),
                      child: const SizedBox.expand(),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAnimatedIcon(primaryYellow),
                        const SizedBox(height: 40),
                        _buildAnimatedText(lightTextColor),
                      ],
                    ),
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
          child: Transform.scale(
            scale: _iconSqueezeAnimation.value,
            child: Transform(
              alignment: Alignment.center,
              transform:
                  Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(math.pi / 2 * (1 - _iconRotationAnimation.value)),
              child: Image.asset('assets/app_icon.png'),
            ),
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
              textAlign: TextAlign.center,
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
              textAlign: TextAlign.center,
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

class ConfettiPainter extends CustomPainter {
  final double animationValue;
  final List<Color> colors;
  final List<Particle> particles;

  ConfettiPainter({required this.animationValue, required this.colors})
    : particles = List.generate(
        100,
        (index) => Particle(
          color: colors[math.Random().nextInt(colors.length)],
          random: math.Random(index),
        ),
      );

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (var particle in particles) {
      final progress = Curves.easeOut.transform(animationValue);
      final path = particle.updatePath(progress, center);

      // --- THIS IS THE FIX ---
      // Replaced .withOpacity() with the more modern .withAlpha()
      final paint =
          Paint()
            ..color = particle.color.withAlpha(
              (255 * (1.0 - progress)).toInt(),
            );
      // --- END OF FIX ---

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => true;
}

class Particle {
  final Color color;
  final math.Random random;
  final double speed;
  final double theta;
  final double drag;
  final double tilt;

  Particle({required this.color, required this.random})
    : speed = random.nextDouble() * 200 + 150,
      theta = random.nextDouble() * 2 * math.pi,
      drag = random.nextDouble() * 0.05 + 0.9,
      tilt = random.nextDouble() * math.pi;

  Path updatePath(double progress, Offset center) {
    final newX = center.dx + math.cos(theta) * speed * progress;
    final newY =
        center.dy +
        math.sin(theta) * speed * progress +
        (150 * progress * progress); // Gravity
    final size = 8.0 * (1 - progress);

    final path = Path();
    path.addRect(
      Rect.fromCenter(center: Offset(newX, newY), width: size, height: size),
    );

    final matrix =
        Matrix4.identity()
          ..translate(newX, newY)
          ..rotateZ(tilt * progress * 2)
          ..translate(-newX, -newY);

    return path.transform(matrix.storage);
  }
}

class FlyingCapsPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  FlyingCapsPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint =
        Paint()
          ..color = color.withAlpha((255 * (1.0 - animationValue)).toInt())
          ..style = PaintingStyle.fill;

    final progress = Curves.easeOut.transform(animationValue);

    for (int i = 0; i < 7; i++) {
      final angle = (i / 7) * 2 * math.pi;
      final distance = progress * size.width * 0.6;

      final capCenter = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      final capSize = 25.0 * (1.0 - progress);
      if (capSize < 2) continue;

      canvas.save();
      canvas.translate(capCenter.dx, capCenter.dy);
      canvas.rotate(progress * math.pi * 2);

      // Draw a simple cap shape
      final path = Path();
      path.moveTo(-capSize / 2, 0);
      path.lineTo(capSize / 2, 0);
      path.lineTo(capSize * 0.3, capSize * 0.4);
      path.lineTo(-capSize * 0.3, capSize * 0.4);
      path.close();
      canvas.drawPath(path, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant FlyingCapsPainter oldDelegate) => true;
}
