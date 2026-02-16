// ===============================
// FILE NAME: edit_profile_screen.dart
// FILE PATH: lib/screens/edit_profile_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:math';
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

  // Controllers
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _statusController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  final _portfolioController = TextEditingController();

  final user = FirebaseAuth.instance.currentUser!;
  bool _isLoading = true;
  String _initialUsername = '';
  String? _profilePhotoUrl; // For display only

  List<String> _departmentOptions = [];
  String? _selectedDepartment;

  // Brand Colors
  final Color _brandPurple = const Color(0xFF9983F3);
  final Color _bgGrey = const Color(0xFFF8F9FE);

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
      // Handle error silently or log
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
          _statusController.text = data['status'] ?? '';
          _linkedinController.text = data['linkedinUrl'] ?? '';
          _githubController.text = data['githubUrl'] ?? '';
          _portfolioController.text = data['portfolioUrl'] ?? '';
          _profilePhotoUrl = data['profilePhotoUrl'];

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
    _statusController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final newUsername = _usernameController.text.trim();
    final newDisplayName = _nameController.text.trim();

    // Username uniqueness check
    if (newUsername.toLowerCase() != _initialUsername.toLowerCase()) {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('searchableUsername', isEqualTo: newUsername.toLowerCase())
              .get();
      if (querySnapshot.docs.isNotEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Username taken. Choose another.'),
            backgroundColor: Colors.redAccent,
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
      final userDoc = await userDocRef.get();
      String? studentId;
      dynamic joinedAt;

      if (userDoc.exists &&
          (userDoc.data() as Map<String, dynamic>).containsKey('studentId')) {
        studentId = userDoc.data()!['studentId'];
        joinedAt = userDoc.data()!['joinedAt'] ?? FieldValue.serverTimestamp();
      } else {
        studentId = (Random().nextInt(900000000) + 100000000).toString();
        joinedAt = FieldValue.serverTimestamp();
      }

      await user.updateDisplayName(newDisplayName);

      final userData = {
        'studentId': studentId,
        'joinedAt': joinedAt,
        'displayName': newDisplayName,
        'username': newUsername,
        'searchableDisplayName': newDisplayName.toLowerCase(),
        'searchableUsername': newUsername.toLowerCase(),
        'bio': _bioController.text.trim(),
        'department': _selectedDepartment,
        'email': user.email,
        'status': _statusController.text.trim(),
        'linkedinUrl': _linkedinController.text.trim(),
        'githubUrl': _githubController.text.trim(),
        'portfolioUrl': _portfolioController.text.trim(),
      };

      await userDocRef.set(userData, SetOptions(merge: true));

      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Profile updated!'),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop(true);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to save: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bgGrey,
        body: Center(child: CircularProgressIndicator(color: _brandPurple)),
      );
    }

    return Scaffold(
      backgroundColor: _bgGrey,
      // Extended App Bar Look
      body: Stack(
        children: [
          // Background Header
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: _brandPurple,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Edit Profile",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          // Avatar
                          Center(
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage:
                                        _profilePhotoUrl != null
                                            ? NetworkImage(_profilePhotoUrl!)
                                            : null,
                                    child:
                                        _profilePhotoUrl == null
                                            ? Icon(
                                              Icons.person,
                                              size: 50,
                                              color: Colors.grey.shade400,
                                            )
                                            : null,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Change Photo in Profile",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Section: Personal Info
                          _buildSectionLabel("Personal Information"),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _buildTextField(
                                  controller: _nameController,
                                  label: "Full Name",
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _usernameController,
                                  label: "Username",
                                  icon: Icons.alternate_email,
                                  isUsername: true,
                                ),
                                const SizedBox(height: 16),
                                _buildDepartmentDropdown(),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _bioController,
                                  label: "Bio",
                                  icon: Icons.info_outline,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _statusController,
                                  label: "Status",
                                  icon: Icons.emoji_emotions_outlined,
                                  hint: "e.g., Studying for finals",
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Section: Social Links
                          _buildSectionLabel("Social Links"),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _buildTextField(
                                  controller: _linkedinController,
                                  label: "LinkedIn",
                                  icon: Icons.link,
                                  keyboardType: TextInputType.url,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _githubController,
                                  label: "GitHub",
                                  icon: Icons.code,
                                  keyboardType: TextInputType.url,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _portfolioController,
                                  label: "Portfolio",
                                  icon: Icons.public,
                                  keyboardType: TextInputType.url,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 100), // Space for FAB
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveProfile,
        backgroundColor: Colors.black87,
        icon: const Icon(Icons.check, color: Colors.white),
        label: Text(
          "Save Changes",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isUsername = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: Colors.grey.shade500,
          fontSize: 13,
        ),
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey.shade300,
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: _brandPurple, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: (value) {
        if (label == 'Full Name' && (value == null || value.isEmpty)) {
          return 'Required';
        }
        if (isUsername) {
          if (value == null || value.isEmpty) return 'Required';
          if (value.contains(' ') || value.contains('@')) {
            return 'Invalid characters';
          }
        }
        return null;
      },
    );
  }

  Widget _buildDepartmentDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDepartment,
      icon: const Icon(Icons.keyboard_arrow_down),
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: "Department",
        labelStyle: GoogleFonts.poppins(
          color: Colors.grey.shade500,
          fontSize: 13,
        ),
        prefixIcon: Icon(Icons.school_outlined, color: _brandPurple, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items:
          _departmentOptions.map((String dept) {
            return DropdownMenuItem(value: dept, child: Text(dept));
          }).toList(),
      onChanged: (val) => setState(() => _selectedDepartment = val),
      validator: (val) => val == null ? 'Required' : null,
    );
  }
}
