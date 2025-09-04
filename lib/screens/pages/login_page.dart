import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Import your reusable widgets. Ensure the paths are correct.
import '../../widgets/custom_auth_button.dart';
import '../../widgets/custom_auth_textfield.dart';

class LoginPage extends StatefulWidget {
  // Callback to communicate with the parent AuthScreen
  final VoidCallback onSignupTapped;

  const LoginPage({super.key, required this.onSignupTapped});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// 1. Add 'with AutomaticKeepAliveClientMixin' to your State class
// This mixin prevents the page from being discarded when it's not visible.
class _LoginPageState extends State<LoginPage>
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

  /// Login with Email and Password
  Future<void> _loginWithEmailPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Login failed'),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  /// Login with Google
  Future<void> _loginWithGoogle() async {
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
          content: Text("Google Login failed. Please try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  /// Forgot Password Function
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address in the field above.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent to your email.'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Failed to send reset email.'),
          backgroundColor: Colors.redAccent,
        ),
      );
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
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/person_and_dog.png',
                  height: 180,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.pets,
                      size: 150,
                      color: primaryAccentColor,
                    );
                  },
                ),
                const SizedBox(height: 30),
                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: secondaryTextColor,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Please, Log In.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: primaryTextColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                CustomAuthTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator:
                      (val) =>
                          val != null && val.contains('@')
                              ? null
                              : 'Enter a valid email',
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
                              : 'Min 6 characters',
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.poppins(
                        color: primaryAccentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                CustomAuthButton(
                  onPressed: _loginWithEmailPassword,
                  text: 'Continue',
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 20),
                Text(
                  'Or',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: secondaryTextColor),
                ),
                const SizedBox(height: 20),
                if (_isGoogleLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                else
                  ElevatedButton.icon(
                    icon: Image.asset('assets/google_logo.png', height: 22.0),
                    label: Text(
                      'Login with Google',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _loginWithGoogle,
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
                      "Don't have an account? ",
                      style: GoogleFonts.poppins(color: secondaryTextColor),
                    ),
                    GestureDetector(
                      onTap:
                          widget
                              .onSignupTapped, // Use the callback to switch pages
                      child: Text(
                        "Sign Up",
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
