import 'dart:math'; // <-- 1. IMPORT FOR RANDOM NUMBER GENERATION
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  List<String> _departmentOptions = [];
  String? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _fetchDepartments();
    await _loadProfileForEditing();
  }

  Future<void> _fetchDepartments() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('departments')
              .orderBy('name')
              .get();
      final departments =
          snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
      if (mounted) {
        setState(() {
          _departmentOptions = departments;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not load departments: $e")),
        );
      }
    }
  }

  Future<void> _loadProfileForEditing() async {
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
          final currentDept = data['department'];
          if (currentDept != null && _departmentOptions.contains(currentDept)) {
            _selectedDepartment = currentDept;
          }
        } else {
          _usernameController.text = user.email?.split('@').first ?? '';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Could not load profile: $e")));
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

  // --- THIS IS THE UPDATED SAVE FUNCTION ---
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final newUsername = _usernameController.text.trim();
    final newDisplayName = _nameController.text.trim();

    if (newUsername.toLowerCase() != _initialUsername.toLowerCase()) {
      final usersRef = FirebaseFirestore.instance.collection('users');
      final querySnapshot =
          await usersRef
              .where('searchableUsername', isEqualTo: newUsername.toLowerCase())
              .get();
      if (querySnapshot.docs.isNotEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('This username is already taken.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Saving profile...')),
    );

    try {
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      // --- 2. LOGIC TO GENERATE STUDENT ID ---
      final userDoc = await userDocRef.get();
      String? studentId;
      if (userDoc.exists &&
          (userDoc.data() as Map<String, dynamic>).containsKey('studentId')) {
        // If ID already exists, keep the existing one.
        studentId = userDoc.data()!['studentId'];
      } else {
        // If no ID exists, generate a new 9-digit random one.
        studentId = (Random().nextInt(900000000) + 100000000).toString();
      }

      await user.updateDisplayName(newDisplayName);

      final userData = {
        'studentId': studentId, // <-- 3. SAVE THE STUDENT ID
        'displayName': newDisplayName,
        'username': newUsername,
        'searchableDisplayName': newDisplayName.toLowerCase(),
        'searchableUsername': newUsername.toLowerCase(),
        'bio': _bioController.text.trim(),
        'links': _linksController.text.trim(),
        'department': _selectedDepartment,
        'email': user.email,
      };
      await userDocRef.set(userData, SetOptions(merge: true));

      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop(true);
    } catch (e) {
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
                    DropdownButtonFormField<String>(
                      value: _selectedDepartment,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                      ),
                      items:
                          _departmentOptions.map((String department) {
                            return DropdownMenuItem<String>(
                              value: department,
                              child: Text(department),
                            );
                          }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedDepartment = newValue;
                        });
                      },
                      validator:
                          (value) =>
                              value == null
                                  ? 'Please select a department'
                                  : null,
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
                      initialValue: user.email,
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
