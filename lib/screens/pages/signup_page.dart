// ===============================
// FILE NAME: signup_page.dart
// FILE PATH: lib/screens/pages/signup_page.dart
// ===============================

import 'dart:async';
import 'dart:ui';
import 'package:email_otp/email_otp.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
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
  final EmailOTP _emailOTP = EmailOTP();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _emailOTP.setConfig(
      appEmail: "support@enterit.ac.in",
      appName: "Ente RIT",
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
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _checkAuthAndNavigate() {
    if (mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/auth-gate', (route) => false);
    }
  }

  // --- STEP 1: SEND OTP ---
  Future<void> _handleSignupStep() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      _emailOTP.setConfig(
        appEmail: "support@enterit.ac.in",
        appName: "Ente RIT",
        userEmail: _emailController.text.trim(),
        otpLength: 6,
        otpType: OTPType.digitsOnly,
      );

      try {
        bool otpSent = await _emailOTP.sendOTP();

        if (mounted) {
          setState(() => _isLoading = false);

          if (otpSent) {
            _showOtpDialog();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  "Failed to send OTP. Please check your email.",
                ),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $e"),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  // --- STEP 2: VERIFY OTP ---
  Future<void> _verifyAndCreateAccount(String pin) async {
    bool isVerified = _emailOTP.verifyOTP(otp: pin);

    if (isVerified) {
      Navigator.of(context).pop(); // Close Dialog
      setState(() => _isLoading = true);

      try {
        await _authService.signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _usernameController.text.trim(),
          _nameController.text.trim(),
        );
        _checkAuthAndNavigate();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst("Exception: ", "")),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Invalid Code. Please try again."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // --- UI: BEAUTIFUL OTP DIALOG ---
  void _showOtpDialog() {
    _otpController.clear();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6), // Dim background
      transitionBuilder: (context, a1, a2, widget) {
        return Transform.scale(
          scale: a1.value,
          child: Opacity(opacity: a1.value, child: widget),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        final defaultPinTheme = PinTheme(
          width: 50,
          height: 55,
          textStyle: GoogleFonts.poppins(
            fontSize: 22,
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161618) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
        );

        final focusedPinTheme = defaultPinTheme.copyDecorationWith(
          border: Border.all(color: const Color(0xFF9983F3), width: 2),
          borderRadius: BorderRadius.circular(12),
          color: isDark ? const Color(0xFF252528) : Colors.white,
        );

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF252528) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.all(32),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF9983F3).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  size: 40,
                  color: Color(0xFF9983F3),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Check your email",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We sent a 6-digit code to\n${_emailController.text}",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),

              Pinput(
                controller: _otpController,
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                onCompleted: (pin) => _verifyAndCreateAccount(pin),
                cursor: Container(
                  width: 2,
                  height: 24,
                  color: const Color(0xFF9983F3),
                ),
              ),

              const SizedBox(height: 32),
              _OtpTimer(
                isDark: isDark,
                onResend: () {
                  Navigator.pop(context);
                  _handleSignupStep();
                },
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.only(bottom: 24),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final inputBgColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: inputBgColor,
            shape: BoxShape.circle,
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 18),
            onPressed: widget.onBackTapped,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Header ---
                      Text(
                        "Create Account",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Start your journey with Ente RIT.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // --- Input Fields ---
                      _buildTextField(
                        controller: _nameController,
                        hint: "Full Name",
                        icon: Icons.person_outline,
                        keyboardType: TextInputType.name,
                        bgColor: inputBgColor,
                        textColor: textColor,
                        isDark: isDark,
                        validator:
                            (val) =>
                                (val == null || val.isEmpty)
                                    ? 'Name is required'
                                    : null,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _usernameController,
                        hint: "Username",
                        icon: Icons.alternate_email,
                        keyboardType: TextInputType.text,
                        bgColor: inputBgColor,
                        textColor: textColor,
                        isDark: isDark,
                        validator: (val) {
                          if (val == null || val.isEmpty)
                            return 'Username is required';
                          if (val.length < 3) return 'Min 3 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _emailController,
                        hint: "Email Address",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        bgColor: inputBgColor,
                        textColor: textColor,
                        isDark: isDark,
                        validator: (val) {
                          if (val == null || val.isEmpty)
                            return 'Email is required';
                          if (!val.contains('@') || !val.contains('.'))
                            return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _passwordController,
                        hint: "Create Password",
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        bgColor: inputBgColor,
                        textColor: textColor,
                        isDark: isDark,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: isDark ? Colors.white30 : Colors.black38,
                            size: 20,
                          ),
                          onPressed:
                              () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                        ),
                        validator:
                            (val) =>
                                val!.length >= 6 ? null : 'Min 6 characters',
                      ),
                      const SizedBox(height: 40),

                      // --- Signup Button ---
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF00C6FB),
                              Color(0xFF005BEA),
                            ], // Cyan to Blue
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF005BEA).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignupStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
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
                                    "Verify & Create Account",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // --- Footer ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: GoogleFonts.poppins(
                              color: subtitleColor,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onLoginTapped,
                            child: Text(
                              "Log In",
                              style: GoogleFonts.poppins(
                                color: const Color(
                                  0xFF00C6FB,
                                ), // Matches gradient
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    required bool isDark,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: isDark ? Colors.white30 : Colors.black38,
          ),
          filled: true,
          fillColor: bgColor,
          contentPadding: const EdgeInsets.all(20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Icon(
            icon,
            color: isDark ? Colors.white54 : Colors.black54,
            size: 22,
          ),
          suffixIcon: suffixIcon,
        ),
        validator: validator,
      ),
    );
  }
}

// --- ISOLATED TIMER WIDGET FOR OTP ---
class _OtpTimer extends StatefulWidget {
  final VoidCallback onResend;
  final bool isDark;

  const _OtpTimer({required this.onResend, required this.isDark});

  @override
  State<_OtpTimer> createState() => _OtpTimerState();
}

class _OtpTimerState extends State<_OtpTimer> {
  int _start = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_start == 0) {
        setState(() => timer.cancel());
      } else {
        setState(() => _start--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_start > 0) {
      return Text(
        "Resend code in 00:${_start.toString().padLeft(2, '0')}",
        style: GoogleFonts.poppins(
          color: widget.isDark ? Colors.white54 : Colors.grey.shade600,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );
    } else {
      return GestureDetector(
        onTap: widget.onResend,
        child: Text(
          "Resend Code",
          style: GoogleFonts.poppins(
            color: const Color(0xFF9983F3),
            fontWeight: FontWeight.bold,
            fontSize: 14,
            decoration: TextDecoration.underline,
          ),
        ),
      );
    }
  }
}
