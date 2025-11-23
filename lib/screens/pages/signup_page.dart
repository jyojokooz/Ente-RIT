// ===============================
// FILE NAME: signup_page.dart
// FILE PATH: lib/screens/pages/signup_page.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/auth_service.dart';

class SignupPage extends StatefulWidget {
  final VoidCallback onLoginTapped;

  const SignupPage({super.key, required this.onLoginTapped});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  // Styles
  final Color brandPurple = const Color(0xFF9983F3);
  final Color darkButtonColor = const Color(0xFF1F2937);
  final OutlineInputBorder _borderStyle = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: Colors.grey.shade200),
  );
  final OutlineInputBorder _focusedBorderStyle = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFF9983F3), width: 1.5),
  );

  Future<void> _signupWithEmailPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Sign up failed"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold ensures white background
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(), // Prevents bounce jitter
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HEADER
                  Text(
                    "Create Account",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Join the Kampus Konnect community",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // EMAIL FIELD
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'RIT Email Address',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50, // Very light grey
                      contentPadding: const EdgeInsets.all(20),
                      enabledBorder: _borderStyle,
                      focusedBorder: _focusedBorderStyle,
                      errorBorder: _borderStyle.copyWith(
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      prefixIcon: Icon(
                        Icons.school_outlined,
                        color: Colors.grey.shade400,
                        size: 22,
                      ),
                    ),
                    validator: (val) {
                      if (val == null || !val.contains('@rit.ac.in')) {
                        return 'Must be an @rit.ac.in address';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // PASSWORD FIELD
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Create Password',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.all(20),
                      enabledBorder: _borderStyle,
                      focusedBorder: _focusedBorderStyle,
                      errorBorder: _borderStyle.copyWith(
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.grey.shade400,
                        size: 22,
                      ),
                    ),
                    validator:
                        (val) =>
                            val != null && val.length >= 6
                                ? null
                                : 'Min 6 characters',
                  ),

                  const SizedBox(height: 32),

                  // SIGN UP BUTTON
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signupWithEmailPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkButtonColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
                                "Sign Up",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // DIVIDER
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade200)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Or sign up with",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade200)),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // GOOGLE BUTTON
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _isGoogleLoading ? null : _signupWithGoogle,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child:
                          _isGoogleLoading
                              ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Using Icon as fallback if asset is missing to prevent error
                                  Image.asset(
                                    'assets/google_logo.png',
                                    height: 24,
                                    errorBuilder:
                                        (ctx, err, stack) => const Icon(
                                          Icons.public,
                                          color: Colors.blue,
                                        ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Google",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF111827),
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // LOGIN REDIRECT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account?",
                        style: GoogleFonts.poppins(color: Colors.grey.shade600),
                      ),
                      TextButton(
                        onPressed: widget.onLoginTapped,
                        child: Text(
                          "Log In",
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
    );
  }
}
