import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  final user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileForEditing();
  }

  /// Fetches the user's current profile from Firestore to populate the form.
  Future<void> _loadProfileForEditing() async {
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();
      if (mounted) {
        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          _nameController.text = data['displayName'] ?? user?.displayName ?? '';
          _usernameController.text =
              data['username'] ?? user?.email?.split('@').first ?? '';
          _bioController.text = data['bio'] ?? '';
          _linksController.text = data['links'] ?? '';
        } else {
          // If no profile exists yet (first time editing), use defaults from Auth.
          _nameController.text = user?.displayName ?? '';
          _usernameController.text = user?.email?.split('@').first ?? '';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile for editing: $e')),
        );
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

  /// Saves the form data to Firestore and updates Firebase Auth.
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && user != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saving profile...')));

      try {
        final userDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid);

        // Also update the display name in Firebase Auth for consistency
        await user!.updateDisplayName(_nameController.text);

        final userData = {
          'displayName': _nameController.text,
          'username': _usernameController.text,
          'bio': _bioController.text,
          'links': _linksController.text,
          'email': user!.email,
        };
        // Use `set` with `merge: true` to create or update the document
        await userDocRef.set(userData, SetOptions(merge: true));

        if (!mounted) return;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        // Pop screen and return `true` to signal a successful update
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          // Disable save button while loading
          if (!_isLoading)
            IconButton(icon: const Icon(Icons.check), onPressed: _saveProfile),
        ],
      ),
      // Show a loading indicator while fetching data
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
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
                      initialValue: user?.email ?? 'No email found',
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        suffixIcon: Icon(Icons.lock),
                        helperText: 'Email cannot be changed from this screen.',
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
