// ===============================
// FILE NAME: login_page.dart
// FILE PATH: lib/screens/pages/login_page.dart
// ===============================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/auth_service.dart';
import 'welcome_page.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onSignupTapped;
  final VoidCallback onBackTapped;

  const LoginPage({
    super.key,
    required this.onSignupTapped,
    required this.onBackTapped,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
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
      duration: const Duration(milliseconds: 800),
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

  // --- FIX: NAVIGATION LOGIC ADDED HERE ---
  void _checkAuthAndNavigate() {
    if (FirebaseAuth.instance.currentUser != null && mounted) {
      // Remove all screens from the stack and go to root
      // This triggers the AuthStateWrapper in main.dart to load MainScreen
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  Future<void> _loginWithEmailPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        _checkAuthAndNavigate(); // FIX CALLED
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? "Login failed"),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      await _authService.signInWithGoogle();
      _checkAuthAndNavigate(); // FIX CALLED
    } catch (e) {
      if (!mounted) return;
      // Ignore cancellation error or successful logins reported as error
      if (FirebaseAuth.instance.currentUser != null) {
        _checkAuthAndNavigate();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Google Sign In Failed"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter email first")));
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reset link sent"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error sending link"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBlack = Colors.black;
    const Color accentYellow = Color(0xFFFFD700);
    const Color accentPink = Color(0xFFFF6B6B);
    const Color accentPurple = Color(0xFF9983F3);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomPaint(size: Size.infinite, painter: DottedBackgroundPainter()),
          Positioned(
            top: -20,
            right: -20,
            child: FloatingShape(
              controller: _floatingController,
              delay: 0.0,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accentYellow, width: 4),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -30,
            child: FloatingShape(
              controller: _floatingController,
              delay: 0.5,
              child: Transform.rotate(
                angle: 0.2,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: accentPink,
                    border: Border.all(color: brandBlack, width: 3),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: 20,
            child: FloatingShape(
              controller: _floatingController,
              delay: 0.2,
              child: const Icon(Icons.star, size: 40, color: accentPurple),
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: brandBlack,
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(0),
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
                                        "WELCOME BACK",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.archivoBlack(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: brandBlack,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Log in to your account.",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 40),

                                NeoBrutalistTextField(
                                  controller: _emailController,
                                  hintText: 'Email Address',
                                  icon: Icons.email_outlined,
                                  validator:
                                      (val) =>
                                          val!.contains('@')
                                              ? null
                                              : 'Enter valid email',
                                ),
                                const SizedBox(height: 20),

                                NeoBrutalistTextField(
                                  controller: _passwordController,
                                  hintText: 'Password',
                                  icon: Icons.lock_outline,
                                  obscureText: true,
                                  validator:
                                      (val) =>
                                          val!.length >= 6
                                              ? null
                                              : 'Min 6 characters',
                                ),
                                const SizedBox(height: 12),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _forgotPassword,
                                    child: Text(
                                      "Forgot Password?",
                                      style: GoogleFonts.spaceMono(
                                        color: brandBlack,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                NeoBrutalistButton(
                                  text: _isLoading ? "LOGGING IN..." : "LOG IN",
                                  onPressed:
                                      _isLoading
                                          ? () {}
                                          : _loginWithEmailPassword,
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
                                          : _loginWithGoogle,
                                  bgColor: Colors.white,
                                  textColor: brandBlack,
                                ),
                                const SizedBox(height: 32),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "New here?",
                                      style: GoogleFonts.spaceMono(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: widget.onSignupTapped,
                                      child: Text(
                                        "Create Account",
                                        style: GoogleFonts.spaceMono(
                                          color: accentPurple,
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

// --- REUSABLE WIDGETS (Same as before, included to prevent errors) ---
class NeoBrutalistTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final String? Function(String?)? validator;

  const NeoBrutalistTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.spaceMono(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.black),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }
}
