// 'dart:async' import has been removed.
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _radiusAnimation;
  late Animation<double> _opacityAnimation;

  static const Color kBackgroundColor = Colors.black;
  static const Color kRevealColor = Colors.yellow;
  static const Color kTextColor = Colors.black;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateUser();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxRadius = sqrt(pow(screenWidth, 2) + pow(screenHeight, 2));

    _radiusAnimation = Tween<double>(begin: 0, end: maxRadius).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 35),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 25),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  void _navigateUser() {
    if (!mounted) return;

    if (FirebaseAuth.instance.currentUser != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              CustomPaint(
                painter: _CircleRevealPainter(
                  radius: _radiusAnimation.value,
                  color: kRevealColor,
                ),
                child: Container(),
              ),
              child!,
            ],
          );
        },
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/welcome_illustration.png',
                  height: 300,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.people,
                      size: 200,
                      color: kTextColor,
                    );
                  },
                ),
                const SizedBox(height: 40),
                Text(
                  'KAMPUS KONNECT',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Text(
                    'Your one-stop destination to Connect, Collaborate, and Thrive on campus.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      // --- FIX APPLIED HERE ---
                      // Replaced deprecated withOpacity with withAlpha. (255 * 0.8 = 204)
                      color: kTextColor.withAlpha(204),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleRevealPainter extends CustomPainter {
  final double radius;
  final Color color;

  _CircleRevealPainter({required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = color;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _CircleRevealPainter oldDelegate) {
    return oldDelegate.radius != radius;
  }
}
