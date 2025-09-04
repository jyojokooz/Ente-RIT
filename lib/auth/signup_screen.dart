import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  String email = '';
  String password = '';
  bool isLoading = false;

  /// Sign up with email and password
  Future<void> _signupWithEmailPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Welcome!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Signup failed'),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  /// Sign up or log in with Google
  Future<void> _signupWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    try {
      setState(() => isLoading = true);
      // It's good practice to sign out first to allow account switching
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => isLoading = false);
        return; // User cancelled the sign-in
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Google Sign-In failed. Please try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- COLOR & THEME UPDATES ---
    const Color screenBackgroundColor = Colors.black;
    const Color primaryAccentColor = Colors.yellow;
    const Color primaryTextColor = Colors.white;
    const Color secondaryTextColor = Colors.white70;
    const Color buttonTextColor = Colors.black;

    return Scaffold(
      backgroundColor: screenBackgroundColor,
      // Add a back button for easy navigation
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/rocket_person.png',
                    height: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.rocket_launch,
                        size: 150,
                        color: primaryAccentColor, // Updated color
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Hi there!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: secondaryTextColor, // Updated color
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Let's Get Started",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor, // Updated color
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    // Set the style for the user's input text
                    style: GoogleFonts.poppins(color: Colors.black),
                    decoration: InputDecoration(
                      // Use labelText for a floating label effect
                      labelText: 'Email Address',
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: Colors.grey,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (val) => email = val,
                    validator:
                        (val) =>
                            val != null &&
                                    val.contains('@') &&
                                    val.contains('.')
                                ? null
                                : 'Please enter a valid email',
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    // Set the style for the user's input text
                    style: GoogleFonts.poppins(color: Colors.black),
                    decoration: InputDecoration(
                      // Use labelText for a floating label effect
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Colors.grey,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    obscureText: true,
                    onChanged: (val) => password = val,
                    validator:
                        (val) =>
                            val != null && val.length >= 6
                                ? null
                                : 'Password must be at least 6 characters',
                  ),
                  const SizedBox(height: 30),
                  if (isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  else ...[
                    // Primary Action Button
                    ElevatedButton(
                      onPressed: _signupWithEmailPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccentColor, // Yellow button
                        foregroundColor: buttonTextColor, // Black text
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        "Create an Account",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Or',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: secondaryTextColor),
                    ),
                    const SizedBox(height: 15),
                    // Google Button - already white, style is perfect
                    ElevatedButton.icon(
                      icon: Image.asset('assets/google_logo.png', height: 22.0),
                      label: Text(
                        'Sign Up with Google',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _signupWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 1,
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  // Navigation to Login Screen
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: GoogleFonts.poppins(color: secondaryTextColor),
                      ),
                      GestureDetector(
                        onTap:
                            () => Navigator.pushReplacementNamed(
                              context,
                              '/login',
                            ),
                        child: Text(
                          "Log In",
                          style: GoogleFonts.poppins(
                            color: primaryAccentColor, // Yellow link text
                            fontWeight: FontWeight.bold,
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
    );
  }
}