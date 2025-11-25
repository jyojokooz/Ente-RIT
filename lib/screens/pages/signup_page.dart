// ===============================
// FILE NAME: signup_page.dart
// FILE PATH: lib/screens/pages/signup_page.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/auth_service.dart';
import 'welcome_page.dart';
import 'login_page.dart'; // Imports NeoBrutalistTextField

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

  // Staggered Animations
  late Animation<Offset> _headerSlide;
  late Animation<double> _headerFade;
  late Animation<Offset> _emailSlide;
  late Animation<double> _emailFade;
  late Animation<Offset> _passwordSlide;
  late Animation<double> _passwordFade;
  late Animation<Offset> _buttonSlide;
  late Animation<double> _buttonFade;
  late Animation<Offset> _dividerSlide;
  late Animation<double> _dividerFade;
  late Animation<Offset> _googleSlide;
  late Animation<double> _googleFade;
  late Animation<Offset> _footerSlide;
  late Animation<double> _footerFade;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    
    Animation<Offset> createSlide(double start, double end) {
      return Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: _entranceController, curve: Interval(start, end, curve: Curves.easeOutCubic)));
    }
    Animation<double> createFade(double start, double end) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entranceController, curve: Interval(start, end, curve: Curves.easeOut)));
    }

    _headerSlide = createSlide(0.0, 0.5); _headerFade = createFade(0.0, 0.4);
    _emailSlide = createSlide(0.1, 0.6); _emailFade = createFade(0.1, 0.5);
    _passwordSlide = createSlide(0.2, 0.7); _passwordFade = createFade(0.2, 0.6);
    _buttonSlide = createSlide(0.3, 0.8); _buttonFade = createFade(0.3, 0.7);
    _dividerSlide = createSlide(0.4, 0.9); _dividerFade = createFade(0.4, 0.8);
    _googleSlide = createSlide(0.5, 0.95); _googleFade = createFade(0.5, 0.9);
    _footerSlide = createSlide(0.6, 1.0); _footerFade = createFade(0.6, 0.95);
    
    // FIX: Delay animation start slightly
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
    _floatingController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _signupWithEmailPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.signUpWithEmailAndPassword(_emailController.text.trim(), _passwordController.text.trim());
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst("Exception: ", "")), backgroundColor: Colors.redAccent));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst("Exception: ", "")), backgroundColor: Colors.redAccent));
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
          Positioned(top: 50, left: 20, child: FloatingShape(controller: _floatingController, delay: 0.0, child: Container(width: 40, height: 40, decoration: BoxDecoration(color: accentYellow, border: Border.all(width: 3))))),
          Positioned(bottom: 50, right: -20, child: FloatingShape(controller: _floatingController, delay: 0.4, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accentBlue, width: 4))))),

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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FadeTransition(
                              opacity: _headerFade,
                              child: SlideTransition(
                                position: _headerSlide,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: accentYellow,
                                    border: Border.all(color: brandBlack, width: 3),
                                    boxShadow: const [BoxShadow(color: brandBlack, offset: Offset(6, 6), blurRadius: 0)],
                                  ),
                                  child: Column(
                                    children: [
                                      Text("JOIN US", textAlign: TextAlign.center, style: GoogleFonts.archivoBlack(fontSize: 28, fontWeight: FontWeight.w900, color: brandBlack)),
                                      const SizedBox(height: 8),
                                      Text("Create your account.", textAlign: TextAlign.center, style: GoogleFonts.spaceMono(fontSize: 14, fontWeight: FontWeight.bold, color: brandBlack)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),

                            FadeTransition(
                              opacity: _emailFade,
                              child: SlideTransition(
                                position: _emailSlide,
                                child: NeoBrutalistTextField(
                                  controller: _emailController,
                                  hintText: 'RIT Email Address',
                                  icon: Icons.school_outlined,
                                  validator: (val) => (val != null && val.contains('@rit.ac.in')) ? null : 'Must use @rit.ac.in email',
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            FadeTransition(
                              opacity: _passwordFade,
                              child: SlideTransition(
                                position: _passwordSlide,
                                child: NeoBrutalistTextField(
                                  controller: _passwordController,
                                  hintText: 'Create Password',
                                  icon: Icons.lock_outline,
                                  obscureText: true,
                                  validator: (val) => val!.length >= 6 ? null : 'Min 6 characters',
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            FadeTransition(
                              opacity: _buttonFade,
                              child: SlideTransition(
                                position: _buttonSlide,
                                child: NeoBrutalistButton(
                                  text: _isLoading ? "CREATING..." : "SIGN UP",
                                  onPressed: _isLoading ? () {} : _signupWithEmailPassword,
                                  bgColor: brandBlack,
                                  textColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            FadeTransition(
                              opacity: _dividerFade,
                              child: SlideTransition(
                                position: _dividerSlide,
                                child: Row(
                                  children: [
                                    const Expanded(child: Divider(color: brandBlack, thickness: 2)),
                                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text("OR", style: GoogleFonts.archivoBlack(fontSize: 14))),
                                    const Expanded(child: Divider(color: brandBlack, thickness: 2)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            FadeTransition(
                              opacity: _googleFade,
                              child: SlideTransition(
                                position: _googleSlide,
                                child: NeoBrutalistButton(
                                  text: "GOOGLE",
                                  onPressed: _isGoogleLoading ? () {} : _signupWithGoogle,
                                  bgColor: Colors.white,
                                  textColor: brandBlack,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            FadeTransition(
                              opacity: _footerFade,
                              child: SlideTransition(
                                position: _footerSlide,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Already a member?", style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold)),
                                    TextButton(
                                      onPressed: widget.onLoginTapped,
                                      child: Text("Log In", style: GoogleFonts.spaceMono(color: accentBlue, fontWeight: FontWeight.w900)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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