// ===============================
// FILE NAME: signup_page.dart
// FILE PATH: lib/screens/pages/signup_page.dart
// ===============================

import 'package:firebase_auth/firebase_auth.dart'; // Needed for check
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/auth_service.dart';
import 'welcome_page.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  final VoidCallback onLoginTapped;
  final VoidCallback onBackTapped;

  const SignupPage({
    super.key,
    required this.onLoginTapped,
    required this.onBackTapped,
  });

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;

  late AnimationController _floatingController;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _floatingController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  // --- FIX: NAVIGATION LOGIC ---
  void _checkAuthAndNavigate() {
    if (FirebaseAuth.instance.currentUser != null && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  Future<void> _signupWithEmailPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        _checkAuthAndNavigate(); // CALL FIX
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst("Exception: ", "")),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signupWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      await _authService.signInWithGoogle();
      _checkAuthAndNavigate(); // CALL FIX
    } catch (e) {
      if (!mounted) return;
      if (FirebaseAuth.instance.currentUser != null) {
        _checkAuthAndNavigate();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst("Exception: ", "")),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBlack = Colors.black;
    const Color accentYellow = Color(0xFFFFD700);
    const Color accentBlue = Color(0xFF4D96FF);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomPaint(size: Size.infinite, painter: DottedBackgroundPainter()),
          Positioned(
            top: 50,
            left: 20,
            child: FloatingShape(
              controller: _floatingController,
              delay: 0.0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentYellow,
                  border: Border.all(width: 3),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            right: -20,
            child: FloatingShape(
              controller: _floatingController,
              delay: 0.4,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accentBlue, width: 4),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: NeoBrutalistButton(
                      text: "BACK",
                      onPressed: widget.onBackTapped,
                      bgColor: Colors.white,
                      textColor: brandBlack,
                      isSmall: true,
                    ),
                  ),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // HEADER
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: accentYellow,
                                    border: Border.all(
                                      color: brandBlack,
                                      width: 3,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: brandBlack,
                                        offset: Offset(6, 6),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        "JOIN US",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.archivoBlack(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: brandBlack,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Create your account.",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: brandBlack,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 40),

                                NeoBrutalistTextField(
                                  controller: _emailController,
                                  hintText: 'RIT Email Address',
                                  icon: Icons.school_outlined,
                                  validator:
                                      (val) =>
                                          (val != null &&
                                                  val.contains('@rit.ac.in'))
                                              ? null
                                              : 'Must use @rit.ac.in email',
                                ),
                                const SizedBox(height: 20),

                                NeoBrutalistTextField(
                                  controller: _passwordController,
                                  hintText: 'Create Password',
                                  icon: Icons.lock_outline,
                                  obscureText: true,
                                  validator:
                                      (val) =>
                                          val!.length >= 6
                                              ? null
                                              : 'Min 6 characters',
                                ),
                                const SizedBox(height: 32),

                                NeoBrutalistButton(
                                  text: _isLoading ? "CREATING..." : "SIGN UP",
                                  onPressed:
                                      _isLoading
                                          ? () {}
                                          : _signupWithEmailPassword,
                                  bgColor: brandBlack,
                                  textColor: Colors.white,
                                ),
                                const SizedBox(height: 24),

                                Row(
                                  children: [
                                    const Expanded(
                                      child: Divider(
                                        color: brandBlack,
                                        thickness: 2,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        "OR",
                                        style: GoogleFonts.archivoBlack(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                      child: Divider(
                                        color: brandBlack,
                                        thickness: 2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                NeoBrutalistButton(
                                  text: "GOOGLE",
                                  onPressed:
                                      _isGoogleLoading
                                          ? () {}
                                          : _signupWithGoogle,
                                  bgColor: Colors.white,
                                  textColor: brandBlack,
                                ),
                                const SizedBox(height: 32),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Already a member?",
                                      style: GoogleFonts.spaceMono(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: widget.onLoginTapped,
                                      child: Text(
                                        "Log In",
                                        style: GoogleFonts.spaceMono(
                                          color: accentBlue,
                                          fontWeight: FontWeight.w900,
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
