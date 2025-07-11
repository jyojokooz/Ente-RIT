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
    // Note: The UI shows "Username", but the backend logic uses email.
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
      // Signing out forces the account picker to always show up.
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // If the user cancels the sign-in
      if (googleUser == null) return;

      setState(() => isLoading = true);

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (!mounted) return;

      // Check if the user is new to show a welcome message
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google account signed up successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged in with Google'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Google Sign-In failed: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define colors from the UI design
    const Color primaryColor = Color(0xFF5A4BDA);
    const Color backgroundColor = Color(0xFFE6E6FA); // A light lavender
    const Color screenBackgroundColor = Color(0xFFC8BFE7);

    return Scaffold(
      backgroundColor: screenBackgroundColor,
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
                  // --- Illustration ---
                  Image.asset(
                    'assets/rocket_person.png',
                    height: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.rocket_launch,
                        size: 150,
                        color: primaryColor,
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- Greeting Text ---
                  Text(
                    'Hi there!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // --- Main Title ---
                  Text(
                    "Let's Get Started",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- Username (Email) Field ---
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Username',
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

                  // --- Password Field ---
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Password',
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

                  // --- Loading Indicator or Buttons ---
                  if (isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  else ...[
                    // --- Create an Account Button ---
                    ElevatedButton(
                      onPressed: _signupWithEmailPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
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

                    // --- 'Or' Divider ---
                    Text(
                      'Or',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                    const SizedBox(height: 15),

                    // --- Google Sign-Up Button ---
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
                    const SizedBox(height: 20),

                    // --- Log In Button (Now at the end) ---
                    ElevatedButton(
                      onPressed:
                          () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: backgroundColor,
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        "Log In",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
