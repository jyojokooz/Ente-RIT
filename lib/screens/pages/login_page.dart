// ===============================
// FILE NAME: login_page.dart
// FILE PATH: lib/screens/pages/login_page.dart
// ===============================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/auth_service.dart';

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

  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _entranceController.forward();
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _checkAuthAndNavigate() {
    if (FirebaseAuth.instance.currentUser != null && mounted) {
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
        _checkAuthAndNavigate();
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
      _checkAuthAndNavigate();
    } catch (e) {
      if (!mounted) return;
      if (FirebaseAuth.instance.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Google Sign In Failed"),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        _checkAuthAndNavigate();
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
    const Color brandPurple = Color(0xFF9983F3);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: widget.onBackTapped,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                      Text(
                        "Welcome Back!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Log in to continue your journey.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 48),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        // FIX: Explicitly set text color to Black
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                        decoration: _buildInputDecoration(
                          "Email",
                          Icons.email_outlined,
                        ),
                        validator:
                            (val) =>
                                val!.contains('@')
                                    ? null
                                    : 'Enter a valid email',
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        // FIX: Explicitly set text color to Black
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                        decoration: _buildInputDecoration(
                          "Password",
                          Icons.lock_outline,
                        ),
                        validator:
                            (val) =>
                                val!.length >= 6 ? null : 'Min 6 characters',
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          child: Text(
                            "Forgot Password?",
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        height: 55,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading ? null : _loginWithEmailPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandPurple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                  : Text(
                                    "Log In",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "or",
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        height: 55,
                        child: OutlinedButton.icon(
                          onPressed: _isGoogleLoading ? null : _loginWithGoogle,
                          icon:
                              _isGoogleLoading
                                  ? const SizedBox.shrink()
                                  : Image.asset(
                                    'assets/google_logo.png',
                                    height: 22,
                                  ),
                          label:
                              _isGoogleLoading
                                  ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                  : Text(
                                    "Continue with Google",
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onSignupTapped,
                            child: Text(
                              "Sign Up",
                              style: GoogleFonts.poppins(
                                color: brandPurple,
                                fontWeight: FontWeight.bold,
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
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
    );
  }
}
