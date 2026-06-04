// ===============================
// FILE NAME: signup_page.dart
// FILE PATH: lib/features/auth/presentation/pages/signup_page.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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

  bool _isLoading = false;
  bool _obscurePassword = true;

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
    _entranceController.dispose();
    super.dispose();
  }

  void _onEmailChanged(String email) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final cleanEmail = email.trim().toLowerCase();

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

    if (!cleanEmail.endsWith('@rit.ac.in')) {
      setState(() {
        _isEmailAvailable = false;
        _isCheckingEmail = false;
        _emailErrorMessage = 'Only @rit.ac.in institution emails are allowed.';
      });
      return;
    }

    setState(() {
      _isCheckingEmail = true;
      _isEmailAvailable = null;
      _emailErrorMessage = null;
    });

    _debounce = Timer(const Duration(milliseconds: 800), () async {
      try {
        bool isTaken = false;

        final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(
          cleanEmail,
        );
        if (methods.isNotEmpty) {
          isTaken = true;
        }

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
          } catch (_) {}
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

  Future<void> _handleSignupStep() async {
    if (_isEmailAvailable == false || _isCheckingEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _emailErrorMessage ??
                "Please use an available @rit.ac.in email address.",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signUpWithEmailAndPassword(
        _emailController.text.trim().toLowerCase(),
        _passwordController.text.trim(),
        _usernameController.text.trim(),
        _nameController.text.trim(),
      );

      // --- AUTOFILL SAVE: Ask Google/OS to save the new password ---
      TextInput.finishAutofillContext();

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showVerificationSentDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showVerificationSentDialog() {
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
                  color: const Color(0xFF00C6FB).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  size: 40,
                  color: Color(0xFF00C6FB),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Verify Your Email",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "We've sent a verification link to\n${_emailController.text.trim()}.\n\nPlease check your inbox and click the link to verify your account before logging in.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    widget.onLoginTapped(); // Switch back to login page
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C6FB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    "Back to Login",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
                  child: AutofillGroup(
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
                          "Use your institution email (@rit.ac.in)",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 40),

                        _buildTextField(
                          controller: _nameController,
                          hint: "Full Name",
                          icon: Icons.person_outline,
                          keyboardType: TextInputType.name,
                          autofillHints: const [AutofillHints.name],
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

                        _buildTextField(
                          controller: _emailController,
                          hint: "Institution Email (@rit.ac.in)",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [
                            AutofillHints.email,
                            AutofillHints.newUsername,
                          ],
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
                            if (!val.toLowerCase().endsWith('@rit.ac.in')) {
                              return 'Must end with @rit.ac.in';
                            }
                            if (_isEmailAvailable == false) {
                              return 'Email already in use';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _passwordController,
                          hint: "Create Password",
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.newPassword],
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
                            if (!RegExp(r'^[\x21-\x7E]+$').hasMatch(val)) {
                              return 'Spaces and emojis are not allowed';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "By signing up, you agree to our Terms of Service and Privacy Policy. Objectionable content or abusive behavior is strictly prohibited and will result in account termination.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color:
                                  isDark
                                      ? Colors.white54
                                      : Colors.grey.shade600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

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
    Iterable<String>? autofillHints,
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
        autofillHints: autofillHints,
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
