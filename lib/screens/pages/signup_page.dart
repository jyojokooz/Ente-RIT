import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Import your reusable widgets. Ensure the paths are correct.
import '../../widgets/custom_auth_button.dart';
import '../../widgets/custom_auth_textfield.dart';

class SignupPage extends StatefulWidget {
  // Callback to communicate with the parent AuthScreen
  final VoidCallback onLoginTapped;

  const SignupPage({super.key, required this.onLoginTapped});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

// 1. Add 'with AutomaticKeepAliveClientMixin' to your State class
// This mixin prevents the page from being discarded when it's not visible.
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

  /// Sign up with email and password
  Future<void> _signupWithEmailPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
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
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  /// Sign up or log in with Google
  Future<void> _signupWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    try {
      setState(() => _isGoogleLoading = true);
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _isGoogleLoading = false);
        return; // User cancelled
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
        const SnackBar(
          content: Text("Google Sign-In failed. Please try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  // 2. Override wantKeepAlive and return true.
  // This tells the framework to keep this widget's state alive.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    // 3. IMPORTANT: Call super.build(context) for the mixin to work.
    super.build(context);

    const Color primaryAccentColor = Colors.yellow;
    const Color primaryTextColor = Colors.white;
    const Color secondaryTextColor = Colors.white70;

    // NO SCAFFOLD OR APPBAR. This is a content widget.
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
                      onTap:
                          widget
                              .onLoginTapped, // Use the callback to switch pages
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
