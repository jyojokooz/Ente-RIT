// lib/auth/pages/signup_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Import your reusable widgets.
import '../../widgets/custom_auth_button.dart';
import '../../widgets/custom_auth_textfield.dart';

class SignupPage extends StatefulWidget {
  // Callback to communicate with the parent AuthScreen
  final VoidCallback onLoginTapped;

  const SignupPage({super.key, required this.onLoginTapped});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

// Using 'AutomaticKeepAliveClientMixin' to preserve the state (like typed text)
// when switching between the Login and Signup tabs in the PageView.
class _SignupPageState extends State<SignupPage>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles user sign-up with email and password.
  Future<void> _signupWithEmailPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // This is the only action needed. Creating the user will trigger the
        // authStateChanges stream in AuthGate, which will then handle
        // navigating the user to the correct screen (CreateUsernameScreen).
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // --- NAVIGATION REMOVED ---
        // We no longer navigate from here. The AuthGate is now responsible
        // for routing the user after a successful sign-up.
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Signup failed. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  /// Handles user sign-up or sign-in with a Google account.
  Future<void> _signupWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    try {
      setState(() => _isGoogleLoading = true);
      // We sign out first to ensure the account picker always appears.
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // The user cancelled the sign-in process.
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Signing in with the credential will trigger the authStateChanges stream
      // in AuthGate, just like the email sign-up.
      await _auth.signInWithCredential(credential);

      // --- NAVIGATION REMOVED ---
      // AuthGate will now check if the user is new (via Firestore) and route
      // them to CreateUsernameScreen, or to MainScreen if they are returning.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Google Sign-In failed. Please try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  // This is required by AutomaticKeepAliveClientMixin.
  // Returning true keeps the widget state alive.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    // This is also required by the mixin.
    super.build(context);

    const Color primaryAccentColor = Colors.yellow;
    const Color primaryTextColor = Colors.white;
    const Color secondaryTextColor = Colors.white70;

    return SafeArea(
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
                      color: primaryAccentColor,
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Hi there!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Let's Get Started",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 30),
                CustomAuthTextField(
                  controller: _emailController,
                  labelText: 'Email Address',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator:
                      (val) =>
                          val != null && val.contains('@') && val.contains('.')
                              ? null
                              : 'Please enter a valid email',
                ),
                const SizedBox(height: 15),
                CustomAuthTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator:
                      (val) =>
                          val != null && val.length >= 6
                              ? null
                              : 'Password must be at least 6 characters',
                ),
                const SizedBox(height: 30),
                CustomAuthButton(
                  onPressed: _signupWithEmailPassword,
                  text: "Create an Account",
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 15),
                Text(
                  'Or',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: secondaryTextColor),
                ),
                const SizedBox(height: 15),
                if (_isGoogleLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                else
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
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: GoogleFonts.poppins(color: secondaryTextColor),
                    ),
                    GestureDetector(
                      onTap: widget.onLoginTapped,
                      child: Text(
                        "Log In",
                        style: GoogleFonts.poppins(
                          color: primaryAccentColor,
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
    );
  }
}
