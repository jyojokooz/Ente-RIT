import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentBio;
  const EditProfileScreen({super.key, required this.currentBio});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _linksController;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _usernameController = TextEditingController(
      text: user?.email?.split('@').first ?? '',
    );
    _bioController = TextEditingController(text: widget.currentBio);
    _linksController = TextEditingController(text: 'yourwebsite.com');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _linksController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saving profile...')));

      await user?.updateDisplayName(_nameController.text);
      // TODO: Save username, bio, links to your database (e.g., Firestore)

      await Future.delayed(const Duration(seconds: 1));

      // FIX: Guard with mounted check and enclose in a block
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      Navigator.of(context).pop(_bioController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveProfile),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) {
                // FIX: Enclose in a block
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
                // FIX: Enclose in a block
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
