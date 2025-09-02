import 'dart:io'; // Required for using the 'File' class.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart'; // For picking images.
import 'package:cloudinary_public/cloudinary_public.dart'; // For uploading to Cloudinary.

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

  String _status = 'lost'; // Default status.
  bool _isLoading = false;

  // State variable to hold the selected image file.
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Initialize Cloudinary with your cloud name and upload preset.
  final cloudinary = CloudinaryPublic(
    "dcboqibnx", // Your Cloudinary Cloud Name
    "flutter_profile_uploads", // Your Cloudinary Upload Preset
    cache: false,
  );

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed.
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Handles picking an image from the gallery or camera.
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70, // Compresses the image to 70% of original quality.
      maxWidth: 800, // Resizes the image to a max width of 800px.
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  /// Handles the entire submission process.
  Future<void> _submitPost() async {
    // First, validate the form fields.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Ensure a user is logged in.
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
      String? imageUrl; // Will be null if no image is selected.

      // If an image was picked, upload it to Cloudinary.
      if (_imageFile != null) {
        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            _imageFile!.path,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
        imageUrl = response.secureUrl;
      }

      // Check if the widget is still mounted after the async upload operation.
      if (!mounted) return;

      // Fetch the user's name to store with the post for easy display.
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (!mounted) return;
      final userName = userDoc.data()?['name'] ?? 'Anonymous';

      // Add the new post to the 'lost_and_found' collection in Firestore.
      await FirebaseFirestore.instance.collection('lost_and_found').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'status': _status,
        'createdAt': Timestamp.now(),
        'userId': user.uid,
        'userName': userName,
        'isResolved': false,
        'imageUrl': imageUrl, // Save the URL from Cloudinary (or null).
      });

      // If successful, pop the screen to return to the previous view.
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      // If any error occurs, show a SnackBar.
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit post: $e')));
      }
    } finally {
      // Ensure the loading indicator is turned off, even if an error occurred.
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
              // --- Image Picker UI ---
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

              // --- Status Dropdown ---
              DropdownButtonFormField<String>(
                value: _status,
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

              // --- Text Form Fields ---
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

              // --- Submit Button ---
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

  /// Shows a bottom sheet with options to pick from Gallery or Camera.
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
