import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );

        // Optional: send email verification
        await userCredential.user?.sendEmailVerification();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created successfully. Please verify your email.',
            ),
          ),
        );

        Navigator.pushReplacementNamed(context, '/home');
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message ?? 'Signup failed')));
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  Future<void> _signupWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(); // ✅ Fixed name

    try {
      await googleSignIn.signOut(); // force account selection
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (!mounted) return;
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google account signed up successfully'),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Logged in with Google')));
      }

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In failed: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text("Create Account", style: TextStyle(fontSize: 24)),
                const SizedBox(height: 20),

                // Email
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (val) => email = val,
                  validator:
                      (val) =>
                          val != null && val.contains('@')
                              ? null
                              : 'Enter valid email',
                ),
                const SizedBox(height: 15),

                // Password
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  onChanged: (val) => password = val,
                  validator:
                      (val) =>
                          val != null && val.length >= 6
                              ? null
                              : 'Min 6 characters',
                ),
                const SizedBox(height: 30),

                // Email Signup Button
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: _signupWithEmailPassword,
                      child: const Text("Sign Up with Email"),
                    ),
                const SizedBox(height: 15),

                // Google Signup Button
                ElevatedButton.icon(
                  icon: Image.asset('assets/google_logo.png', height: 24),
                  label: const Text('Sign Up with Google'),
                  onPressed: _signupWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),

                // Navigate to Login
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text("Already have an account? Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
