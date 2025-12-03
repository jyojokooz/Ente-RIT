// ===============================
// FILE NAME: signup_page.dart
// FILE PATH: lib/screens/pages/signup_page.dart
// ===============================

import 'package:email_otp/email_otp.dart'; // Import the package
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/auth_service.dart';

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

  // OTP Object
  final EmailOTP _emailOTP = EmailOTP();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController(); // Controller for OTP input

  bool _isLoading = false;

  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Configure OTP Service
    _emailOTP.setConfig(
      appEmail: "support@kampuskonnect.com",
      appName: "Kampus Konnect",
      userEmail: _emailController.text,
      otpLength: 6,
      otpType: OTPType.digitsOnly,
    );

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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _checkAuthAndNavigate() {
    if (FirebaseAuth.instance.currentUser != null && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  // --- STEP 1: SEND OTP ---
  Future<void> _handleSignupStep() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Update the email in the OTP config dynamically
      _emailOTP.setConfig(
        appEmail: "verify@kampuskonnect.com",
        appName: "Kampus Konnect",
        userEmail: _emailController.text.trim(),
        otpLength: 6,
        otpType: OTPType.digitsOnly,
      );

      try {
        // Send OTP
        bool otpSent = await _emailOTP.sendOTP();

        if (mounted) {
          setState(() => _isLoading = false);

          if (otpSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("OTP sent to your email"),
                backgroundColor: Colors.green,
              ),
            );
            // Open the verification dialog
            _showOtpDialog();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Failed to send OTP. Try again."),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // --- STEP 2: VERIFY OTP AND CREATE ACCOUNT ---
  Future<void> _verifyAndCreateAccount() async {
    // 1. Verify OTP
    bool isVerified = _emailOTP.verifyOTP(otp: _otpController.text.trim());

    if (isVerified) {
      Navigator.of(context).pop(); // Close dialog
      setState(() => _isLoading = true);

      try {
        // 2. Create Firebase Account
        await _authService.signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _usernameController.text.trim(),
        );
        _checkAuthAndNavigate();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst("Exception: ", "")),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid OTP"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- UI: OTP DIALOG ---
  void _showOtpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            "Enter Verification Code",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "We sent a code to ${_emailController.text}",
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 5,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: _verifyAndCreateAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9983F3),
                foregroundColor: Colors.white,
              ),
              child: Text(
                "Verify",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- HEADER ---
                      Text(
                        "Create an Account",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Start your journey with Kampus Konnect.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // --- USERNAME ---
                      TextFormField(
                        controller: _usernameController,
                        keyboardType: TextInputType.text,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                        decoration: _buildInputDecoration(
                          "Username",
                          Icons.person_outline,
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty)
                            return 'Username is required';
                          if (val.length < 3) return 'Min 3 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // --- EMAIL ---
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                        decoration: _buildInputDecoration(
                          "Email Address",
                          Icons.email_outlined,
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty)
                            return 'Email is required';
                          if (!val.contains('@') || !val.contains('.'))
                            return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // --- PASSWORD ---
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                        decoration: _buildInputDecoration(
                          "Create Password",
                          Icons.lock_outline,
                        ),
                        validator:
                            (val) =>
                                val!.length >= 6 ? null : 'Min 6 characters',
                      ),
                      const SizedBox(height: 32),

                      // --- SIGN UP BUTTON (NOW SENDS OTP) ---
                      SizedBox(
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignupStep,
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
                                    "Verify & Create Account", // Changed Label
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // --- LOGIN LINK ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onLoginTapped,
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
