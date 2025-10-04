// lib/screens/edit_lost_found_post_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class EditLostFoundPostScreen extends StatefulWidget {
  final QueryDocumentSnapshot itemDoc;
  const EditLostFoundPostScreen({super.key, required this.itemDoc});

  @override
  State<EditLostFoundPostScreen> createState() =>
      _EditLostFoundPostScreenState();
}

class _EditLostFoundPostScreenState extends State<EditLostFoundPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late String _status;
  String? _currentImageUrl;
  bool _isLoading = false;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final cloudinary = CloudinaryPublic(
    "dcboqibnx",
    "flutter_profile_uploads",
    cache: false,
  );

  @override
  void initState() {
    super.initState();
    final data = widget.itemDoc.data() as Map<String, dynamic>;
    _titleController = TextEditingController(text: data['title'] ?? '');
    _descriptionController = TextEditingController(
      text: data['description'] ?? '',
    );
    _locationController = TextEditingController(text: data['location'] ?? '');
    _status = data['status'] ?? 'lost';
    _currentImageUrl = data['imageUrl'];
  }

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
        _currentImageUrl = null;
      });
    }
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    String? finalImageUrl = widget.itemDoc['imageUrl'];

    try {
      if (_imageFile != null) {
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            _imageFile!.path,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
        finalImageUrl = response.secureUrl;
      }
      if (!mounted) return;

      await FirebaseFirestore.instance
          .collection('lost_and_found')
          .doc(widget.itemDoc.id)
          .update({
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'location': _locationController.text.trim(),
            'status': _status,
            'imageUrl': finalImageUrl,
          });

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated successfully!')),
      );
    } catch (e) {
      // --- FIX: Added curly braces {} ---
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update post: $e')));
      }
    } finally {
      // --- FIX: Added curly braces {} ---
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Edit Item', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        _imageFile != null
                            ? Image.file(_imageFile!, fit: BoxFit.cover)
                            : (_currentImageUrl != null &&
                                    _currentImageUrl!.isNotEmpty
                                ? Image.network(
                                  _currentImageUrl!,
                                  fit: BoxFit.cover,
                                )
                                : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt_outlined,
                                        color: Colors.white70,
                                        size: 50,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Change photo',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                )),
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
                decoration: const InputDecoration(labelText: 'Item Title'),
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
                onPressed: _isLoading ? null : _submitUpdate,
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
                          'Save Changes',
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
