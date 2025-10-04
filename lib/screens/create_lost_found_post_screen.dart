// lib/screens/create_lost_found_post_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:developer' as developer;

class CreateLostFoundPostScreen extends StatefulWidget {
  const CreateLostFoundPostScreen({super.key});

  @override
  State<CreateLostFoundPostScreen> createState() =>
      _CreateLostFoundPostScreenState();
}

class _CreateLostFoundPostScreenState extends State<CreateLostFoundPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String _status = 'lost';
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final cloudinary = CloudinaryPublic(
    "dcboqibnx",
    "flutter_profile_uploads",
    cache: false,
  );

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 800,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to post.')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;
      if (_imageFile != null) {
        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            _imageFile!.path,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
        imageUrl = response.secureUrl;
      }
      if (!mounted) return;

      // --- THE DEFINITIVE FIX ---
      // Instead of querying Firestore again, get the name DIRECTLY from the auth object.
      // This is the most immediate and reliable source of the user's name after sign-in.
      // We provide fallbacks just in case, making it incredibly robust.
      final String userName = user.displayName ?? user.email ?? 'Anonymous';

      developer.log(
        "Using user name from Auth object: '$userName'",
        name: "SubmitPost",
      );
      // --- END OF THE DEFINITIVE FIX ---

      await FirebaseFirestore.instance.collection('lost_and_found').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'status': _status,
        'createdAt': Timestamp.now(),
        'userId': user.uid,
        'userName': userName, // Use the name from the Auth object.
        'isResolved': false,
        'imageUrl': imageUrl,
      });

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit post: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // The build method is unchanged.
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: Text('Report an Item', style: GoogleFonts.poppins()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: () => _showImagePickerOptions(context),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade700),
                  ),
                  child:
                      _imageFile != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          )
                          : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white70,
                                size: 50,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Add a photo (optional)',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _status,
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Status',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.grey.shade800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: Colors.grey.shade800,
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(
                    value: 'lost',
                    child: Text('I Lost Something'),
                  ),
                  DropdownMenuItem(
                    value: 'found',
                    child: Text('I Found Something'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Item Title (e.g., Black Wallet)',
                ),
                validator:
                    (value) =>
                        value!.trim().isEmpty ? 'Please enter a title.' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
                validator:
                    (value) =>
                        value!.trim().isEmpty
                            ? 'Please enter a description.'
                            : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _locationController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Last Known Location',
                ),
                validator:
                    (value) =>
                        value!.trim().isEmpty
                            ? 'Please enter a location.'
                            : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.black,
                          ),
                        )
                        : Text(
                          'Submit Post',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      builder: (builder) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text(
                  'Gallery',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.white),
                title: const Text(
                  'Camera',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
