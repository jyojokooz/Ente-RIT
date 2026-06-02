// ===============================
// FILE NAME: signup_page.dart
// FILE PATH: lib/screens/pages/signup_page.dart
// ===============================

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_project/features/auth/data/auth_service.dart';

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

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _generatedOtp;

  // --- Real-Time Email Checking State ---
  Timer? _debounce;
  bool _isCheckingEmail = false;
  bool? _isEmailAvailable;
  String? _emailErrorMessage;

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
    _debounce?.cancel();
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

  // --- REAL-TIME EMAIL CHECK LOGIC ---
  void _onEmailChanged(String email) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final cleanEmail = email.trim();

    // Reset states if field is empty or invalid format
    if (cleanEmail.isEmpty ||
        !cleanEmail.contains('@') ||
        !cleanEmail.contains('.')) {
      setState(() {
        _isEmailAvailable = null;
        _isCheckingEmail = false;
        _emailErrorMessage = null;
      });
      return;
    }

    // Start checking state
    setState(() {
      _isCheckingEmail = true;
      _isEmailAvailable = null;
      _emailErrorMessage = null;
    });

    // Debounce to avoid spamming the database on every single keystroke
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      try {
        bool isTaken = false;

        // METHOD 1: Check Firebase Auth directly
        final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(
          cleanEmail,
        );
        if (methods.isNotEmpty) {
          isTaken = true;
        }

        // METHOD 2: Fallback check against Firestore
        if (!isTaken) {
          try {
            final query =
                await FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: cleanEmail)
                    .limit(1)
                    .get();
            if (query.docs.isNotEmpty) {
              isTaken = true;
            }
          } catch (_) {
            // Ignore permission denied errors
          }
        }

        if (mounted) {
          setState(() {
            _isCheckingEmail = false;
            if (isTaken) {
              _isEmailAvailable = false;
              _emailErrorMessage = 'This email is already registered.';
            } else {
              _isEmailAvailable = true;
              _emailErrorMessage = null;
            }
          });
        }
      } catch (e) {
        debugPrint("Email validation error: $e");
        if (mounted) {
          setState(() {
            _isCheckingEmail = false;
            _isEmailAvailable = null;
            _emailErrorMessage = null;
          });
        }
      }
    });
  }

  // --- STEP 1: GENERATE AND SEND OTP USING MAILER ---
  Future<void> _handleSignupStep() async {
    // Prevent sending if email is taken or still being checked
    if (_isEmailAvailable == false || _isCheckingEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please use an available email address."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Generate a random 6-digit OTP
      _generatedOtp = (100000 + Random().nextInt(900000)).toString();

      // Retrieve credentials from .env
      String senderEmail = dotenv.env['SMTP_EMAIL'] ?? '';
      String senderPassword = dotenv.env['SMTP_PASSWORD'] ?? '';

      if (senderEmail.isEmpty || senderPassword.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("SMTP credentials are not configured in .env"),
          ),
        );
        return;
      }

      final smtpServer = gmail(senderEmail, senderPassword);

      final message =
          Message()
            ..from = Address(senderEmail, 'Ente RIT Support')
            ..recipients.add(_emailController.text.trim())
            ..subject = 'Your Verification Code for Ente RIT'
            ..html = '''
          <!DOCTYPE html>
          <html>
          <body style="font-family: Arial, sans-serif; background-color: #f9f9f9; padding: 20px;">
            <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; padding: 30px; border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.05);">
              <h2 style="color: #9983F3; margin-top: 0;">Welcome to Ente RIT!</h2>
              <p style="color: #333333; font-size: 16px;">Hi ${_nameController.text.trim()},</p>
              <p style="color: #555555; font-size: 15px; line-height: 1.5;">
                Thank you for registering. To complete your secure sign-up process, please use the 6-digit verification code below:
              </p>
              <div style="background-color: #f4f4f4; padding: 20px; border-radius: 8px; font-size: 28px; font-weight: bold; letter-spacing: 8px; text-align: center; color: #222; margin: 30px 0;">
                $_generatedOtp
              </div>
              <p style="color: #555555; font-size: 14px;">
                Please note: This code will expire in 10 minutes. Do not share this code with anyone.
              </p>
            </div>
          </body>
          </html>
        ''';

      try {
        await send(message, smtpServer);

        if (mounted) {
          setState(() => _isLoading = false);
          _showOtpDialog();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to send email: $e"),
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

  // --- STEP 2: VERIFY LOCALLY STORED OTP ---
  Future<void> _verifyAndCreateAccount(String pin) async {
    if (pin == _generatedOtp) {
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
          setState(() {
            _isLoading = false;
            // FAILSAFE: If Firebase rejects it here, immediately update the text field to show the Red Cross.
            if (e.toString().contains('email-already-in-use') ||
                e.toString().contains('already in use')) {
              _isEmailAvailable = false;
              _emailErrorMessage =
                  'The email address is already in use by another account.';
            }
          });
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
      _otpController.clear();
    }
  }

  void _showOtpDialog() {
    _otpController.clear();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
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

                      // NAME FIELD WITH EMOJI/SPECIAL CHARACTER BLOCKER
                      _buildTextField(
                        controller: _nameController,
                        hint: "Full Name",
                        icon: Icons.person_outline,
                        keyboardType: TextInputType.name,
                        bgColor: inputBgColor,
                        textColor: textColor,
                        isDark: isDark,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Name is required';
                          }
                          if (val.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(val)) {
                            return 'Only letters and spaces are allowed';
                          }
                          return null;
                        },
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
                          if (val == null || val.isEmpty) {
                            return 'Username is required';
                          }
                          if (val.length < 3) return 'Min 3 characters';
                          if (!RegExp(r"^[a-zA-Z0-9_.]+$").hasMatch(val)) {
                            return 'Only letters, numbers, _ and . allowed';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email Field with Real-Time Validation
                      _buildTextField(
                        controller: _emailController,
                        hint: "Email Address",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        bgColor: inputBgColor,
                        textColor: textColor,
                        isDark: isDark,
                        onChanged: _onEmailChanged,
                        errorText: _emailErrorMessage,
                        suffixIcon:
                            _isCheckingEmail
                                ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF00C6FB),
                                    ),
                                  ),
                                )
                                : _isEmailAvailable == true
                                ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                                : _isEmailAvailable == false
                                ? const Icon(Icons.cancel, color: Colors.red)
                                : null,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Email is required';
                          }
                          if (!val.contains('@') || !val.contains('.')) {
                            return 'Enter a valid email';
                          }
                          if (_isEmailAvailable == false) {
                            return 'Email already in use';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // PASSWORD FIELD WITH EMOJI & SPACE BLOCKER
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
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Password is required';
                          }
                          if (val.length < 6) return 'Min 6 characters';
                          // Ensures no emojis and no spaces. Allows only visible ASCII chars.
                          if (!RegExp(r'^[\x21-\x7E]+$').hasMatch(val)) {
                            return 'Spaces and emojis are not allowed';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00C6FB), Color(0xFF005BEA)],
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
                                color: const Color(0xFF00C6FB),
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
    String? errorText,
    void Function(String)? onChanged,
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
        onChanged: onChanged,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        decoration: InputDecoration(
          hintText: hint,
          errorText: errorText,
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
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
