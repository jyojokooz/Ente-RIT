import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // It's good practice to import what you use

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _linksController = TextEditingController();

  final user = FirebaseAuth.instance.currentUser!;
  bool _isLoading = true;
  String _initialUsername = '';

  @override
  void initState() {
    super.initState();
    _loadProfileForEditing();
  }

  Future<void> _loadProfileForEditing() async {
    setState(() => _isLoading = true);
    try {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (mounted) {
        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          _nameController.text = data['displayName'] ?? user.displayName ?? '';
          _usernameController.text = data['username'] ?? '';
          _initialUsername = data['username'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _linksController.text = data['links'] ?? '';
        } else {
          _nameController.text = user.displayName ?? '';
          _usernameController.text = user.email?.split('@').first ?? '';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _linksController.dispose();
    super.dispose();
  }

  // --- THIS IS THE CORRECTED SAVE FUNCTION ---
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // --- FIX APPLIED HERE ---
    // Capture context-dependent objects BEFORE the first await.
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final newUsername = _usernameController.text.trim();
    final newDisplayName = _nameController.text.trim();

    // Check if the username has been changed
    if (newUsername.toLowerCase() != _initialUsername.toLowerCase()) {
      final usersRef = FirebaseFirestore.instance.collection('users');
      final querySnapshot =
          await usersRef
              .where('searchableUsername', isEqualTo: newUsername.toLowerCase())
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Username is taken. Use the captured scaffoldMessenger.
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text(
              'This username is already taken. Please choose another.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Show saving message
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Saving profile...')),
    );

    try {
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      await user.updateDisplayName(newDisplayName);

      final userData = {
        'displayName': newDisplayName,
        'username': newUsername,
        'searchableDisplayName': newDisplayName.toLowerCase(),
        'searchableUsername': newUsername.toLowerCase(),
        'bio': _bioController.text.trim(),
        'links': _linksController.text.trim(),
        'email': user.email,
      };
      await userDocRef.set(userData, SetOptions(merge: true));

      if (!mounted) return;

      // Use captured objects. This is now safe.
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to save profile: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
        actions: [
          if (!_isLoading)
            IconButton(icon: const Icon(Icons.check), onPressed: _saveProfile),
        ],
      ),
      backgroundColor: Colors.black,
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.yellow),
              )
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator:
                          (v) => v!.isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
                        }
                        if (value.contains(' ') || value.contains('@')) {
                          return 'Username cannot contain spaces or @';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'Bio'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _linksController,
                      decoration: const InputDecoration(labelText: 'Links'),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      initialValue: user.email ?? 'No email found',
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        suffixIcon: Icon(Icons.lock),
                        helperText: 'Email cannot be changed.',
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
