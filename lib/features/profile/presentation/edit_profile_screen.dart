// ===============================
// FILE NAME: edit_profile_screen.dart
// FILE PATH: C:\Ente-RITEEE\Ente-RIT\lib\features\profile\presentation\edit_profile_screen.dart
// ===============================

import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart'; // <-- ADDED FOR CROPPING

// Import sub-components through the newly created connector file
import 'package:my_project/features/profile/presentation/widgets/edit_profile_components.dart';

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
  bool _isSaving = false;
  bool _isUploadingImage = false;

  String _initialUsername = '';
  DateTime?
  _lastUsernameChange; // <-- Tracks when the username was last changed
  String? _profilePhotoUrl;

  List<String> _departmentOptions = [];
  String? _selectedDepartment;

  final ImagePicker _picker = ImagePicker();

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
      debugPrint("Error fetching departments: $e");
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

          // Get the last username change date
          _lastUsernameChange =
              (data['lastUsernameChange'] as Timestamp?)?.toDate();

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

  // --- IMAGE UPLOAD & CROP LOGIC ---
  Future<void> _pickAndUploadImage() async {
    if (_isUploadingImage) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1080,
      );

      if (pickedFile == null) return;

      // 1. Crop the Image
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFFFF4B72), // Brand Pink
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true, // Lock to 1:1 for profile pictures
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );

      if (croppedFile == null) return; // User cancelled cropping

      setState(() => _isUploadingImage = true);

      // 2. Upload the Cropped Image
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/${user.uid}')
          .child(fileName);

      await ref.putFile(
        File(croppedFile.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await ref.getDownloadURL();

      // Immediately save the new URL to Firestore so it reflects everywhere
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'profilePhotoUrl': downloadUrl},
      );

      // Automatically update all existing posts/comments with the new photo
      await _updateDenormalizedData(null, downloadUrl);

      setState(() {
        _profilePhotoUrl = downloadUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to upload image: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // --- SAVE PROFILE LOGIC ---
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final newUsername = _usernameController.text.trim();
    final newDisplayName = _nameController.text.trim();

    final bool usernameChanged =
        newUsername.toLowerCase() != _initialUsername.toLowerCase();

    // Username checks: 30 days restriction and uniqueness
    if (usernameChanged) {
      // 1. Enforce 30 days rule
      if (_lastUsernameChange != null) {
        final difference = DateTime.now().difference(_lastUsernameChange!);
        if (difference.inDays < 30) {
          final daysLeft = 30 - difference.inDays;
          setState(() => _isSaving = false);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                'You can change your username again in $daysLeft days.',
              ),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
      }

      // 2. Uniqueness Check (Only fails if another active user owns it)
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('searchableUsername', isEqualTo: newUsername.toLowerCase())
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() => _isSaving = false);
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Username taken by an active user. Please choose another.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

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
        'status': _statusController.text.trim(),
        'linkedinUrl': _linkedinController.text.trim(),
        'githubUrl': _githubController.text.trim(),
        'portfolioUrl': _portfolioController.text.trim(),
        // Update the timestamp only if the username actually changed
        if (usernameChanged) 'lastUsernameChange': FieldValue.serverTimestamp(),
      };

      await userDocRef.set(userData, SetOptions(merge: true));

      // Automatically update all existing posts/comments with the new name
      await _updateDenormalizedData(newDisplayName, null);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop(true);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to save: ${e.toString()}')),
      );
      setState(() => _isSaving = false);
    }
  }

  // BATCH UPDATER FUNCTION
  Future<void> _updateDenormalizedData(
    String? newName,
    String? newPhotoUrl,
  ) async {
    if (newName == null && newPhotoUrl == null) return;

    final uid = user.uid;
    final firestore = FirebaseFirestore.instance;
    WriteBatch batch = firestore.batch();
    int operationCount = 0;

    Future<void> commitBatchIfLimitReached() async {
      if (operationCount >= 450) {
        await batch.commit();
        batch = firestore.batch();
        operationCount = 0;
      }
    }

    try {
      // 1. Update Posts
      final postsSnap =
          await firestore
              .collection('posts')
              .where('userId', isEqualTo: uid)
              .get();
      for (var doc in postsSnap.docs) {
        Map<String, dynamic> updates = {};
        if (newName != null) updates['userName'] = newName;
        if (newPhotoUrl != null) updates['userImageUrl'] = newPhotoUrl;
        if (updates.isNotEmpty) {
          batch.update(doc.reference, updates);
          operationCount++;
          await commitBatchIfLimitReached();
        }
      }

      // 2. Update Comments
      try {
        final commentsSnap =
            await firestore
                .collectionGroup('comments')
                .where('userId', isEqualTo: uid)
                .get();
        for (var doc in commentsSnap.docs) {
          Map<String, dynamic> updates = {};
          if (newName != null) updates['userName'] = newName;
          if (newPhotoUrl != null) updates['userImageUrl'] = newPhotoUrl;
          if (updates.isNotEmpty) {
            batch.update(doc.reference, updates);
            operationCount++;
            await commitBatchIfLimitReached();
          }
        }
      } catch (e) {
        debugPrint("Comments update skipped (missing index?): $e");
      }

      // 3. Update Marketplace Products
      final productsSnap =
          await firestore
              .collection('products')
              .where('sellerId', isEqualTo: uid)
              .get();
      for (var doc in productsSnap.docs) {
        Map<String, dynamic> updates = {};
        if (newName != null) updates['sellerName'] = newName;
        if (newPhotoUrl != null) updates['sellerPhotoUrl'] = newPhotoUrl;
        if (updates.isNotEmpty) {
          batch.update(doc.reference, updates);
          operationCount++;
          await commitBatchIfLimitReached();
        }
      }

      // 4. Update Stories
      final storiesSnap =
          await firestore
              .collection('stories')
              .where('userId', isEqualTo: uid)
              .get();
      for (var doc in storiesSnap.docs) {
        Map<String, dynamic> updates = {};
        if (newName != null) updates['userName'] = newName;
        if (newPhotoUrl != null) updates['userImage'] = newPhotoUrl;
        if (updates.isNotEmpty) {
          batch.update(doc.reference, updates);
          operationCount++;
          await commitBatchIfLimitReached();
        }
      }

      // 5. Update Lost and Found
      if (newName != null) {
        final lfSnap =
            await firestore
                .collection('lost_and_found')
                .where('userId', isEqualTo: uid)
                .get();
        for (var doc in lfSnap.docs) {
          batch.update(doc.reference, {'userName': newName});
          operationCount++;
          await commitBatchIfLimitReached();
        }
      }

      // 6. Update Active Chats
      final chatsSnap =
          await firestore
              .collection('chats')
              .where('participants', arrayContains: uid)
              .get();
      for (var doc in chatsSnap.docs) {
        Map<String, dynamic> updates = {};
        if (newName != null) updates['participantNames.$uid'] = newName;
        if (newPhotoUrl != null) {
          updates['participantImages.$uid'] = newPhotoUrl;
        }
        if (updates.isNotEmpty) {
          batch.update(doc.reference, updates);
          operationCount++;
          await commitBatchIfLimitReached();
        }
      }

      // 7. Update Sent Notifications
      final notifSnap =
          await firestore
              .collection('notifications')
              .where('triggeringUserId', isEqualTo: uid)
              .get();
      for (var doc in notifSnap.docs) {
        Map<String, dynamic> updates = {};
        if (newName != null) updates['triggeringUserName'] = newName;
        if (newPhotoUrl != null) {
          updates['triggeringUserAvatarUrl'] = newPhotoUrl;
        }
        if (updates.isNotEmpty) {
          batch.update(doc.reference, updates);
          operationCount++;
          await commitBatchIfLimitReached();
        }
      }

      // Final commit
      if (operationCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint("Error updating denormalized data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.grey.shade600;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF3E8E)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Profile",
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF00C6FB),
                    Color(0xFF005BEA),
                  ], // Blue Gradient
                ),
              ),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child:
                    _isSaving
                        ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          "Save",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // --- AVATAR COMPONENT ---
              EditProfileAvatar(
                profilePhotoUrl: _profilePhotoUrl,
                isUploadingImage: _isUploadingImage,
                isDark: isDark,
                bgColor: bgColor,
                subtitleColor: subtitleColor,
                onPickImage: _pickAndUploadImage,
              ),
              const SizedBox(height: 32),

              // --- FORM COMPONENT ---
              EditProfileForm(
                formKey: _formKey,
                nameController: _nameController,
                usernameController: _usernameController,
                bioController: _bioController,
                statusController: _statusController,
                linkedinController: _linkedinController,
                githubController: _githubController,
                portfolioController: _portfolioController,
                departmentOptions: _departmentOptions,
                selectedDepartment: _selectedDepartment,
                onDepartmentChanged: (val) {
                  setState(() => _selectedDepartment = val);
                },
                cardColor: cardColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                isDark: isDark,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
