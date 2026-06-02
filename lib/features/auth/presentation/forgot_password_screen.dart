import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  bool isLoading = false;

  void _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());

        if (!mounted) return; // ✅ Check if widget is still in tree
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password reset email sent")),
        );

        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return; // ✅ Again, check before using context
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  "Reset Your Password",
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Enter your email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (val) => email = val,
                  validator:
                      (val) =>
                          val != null && val.contains('@')
                              ? null
                              : 'Enter valid email',
                ),
                const SizedBox(height: 30),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: _resetPassword,
                      child: const Text("Send Reset Email"),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
