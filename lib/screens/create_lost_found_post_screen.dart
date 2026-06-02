import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

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
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_imageFile != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${_imageFile!.path.split('/').last}';
        final ref = FirebaseStorage.instance
            .ref()
            .child('lost_and_found')
            .child(fileName);

        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      if (!mounted) return;

      final String userName = user.displayName ?? user.email ?? 'Anonymous';

      await FirebaseFirestore.instance.collection('lost_and_found').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'status': _status,
        'createdAt': Timestamp.now(),
        'userId': user.uid,
        'userName': userName,
        'isResolved': false,
        'imageUrl': imageUrl,
      });

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputColor = isDark ? const Color(0xFF252528) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Report an Item',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Segmented Control for Status
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: inputColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    _buildStatusTab('lost', 'I Lost It', isDark, inputColor),
                    _buildStatusTab('found', 'I Found It', isDark, inputColor),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Image Picker
              GestureDetector(
                onTap: () => _showImagePickerOptions(context, isDark),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: inputColor,
                    borderRadius: BorderRadius.circular(24),
                    image:
                        _imageFile != null
                            ? DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            )
                            : null,
                  ),
                  child:
                      _imageFile == null
                          ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_rounded,
                                color: theme.colorScheme.primary,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add a photo (optional)',
                                style: GoogleFonts.poppins(
                                  color:
                                      isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            ],
                          )
                          : null,
                ),
              ),
              const SizedBox(height: 24),

              // Text Fields
              _buildTextField(
                _titleController,
                'Item Title (e.g., Black Wallet)',
                inputColor,
                textColor,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _locationController,
                'Last Known Location',
                inputColor,
                textColor,
                icon: Icons.location_on_outlined,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _descriptionController,
                'Description',
                inputColor,
                textColor,
                maxLines: 4,
                isRequired: true,
              ),

              const SizedBox(height: 40),

              // Submit Button
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF3E8E), Color(0xFFFF9A44)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            'Submit Report',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTab(
    String status,
    String label,
    bool isDark,
    Color inputColor,
  ) {
    final isSelected = _status == status;
    final gradient =
        isSelected
            ? LinearGradient(
              colors:
                  status == 'lost'
                      ? [const Color(0xFFFF9A44), const Color(0xFFFF3E8E)]
                      : [const Color(0xFF00C6FB), const Color(0xFF005BEA)],
            )
            : null;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _status = status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: gradient,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color:
                  isSelected
                      ? Colors.white
                      : (isDark ? Colors.white54 : Colors.black54),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    Color bgColor,
    Color textColor, {
    int maxLines = 1,
    bool isRequired = false,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.poppins(color: textColor, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.3)),
        prefixIcon:
            icon != null
                ? Icon(icon, color: textColor.withOpacity(0.5), size: 20)
                : null,
        filled: true,
        fillColor: bgColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
      validator:
          isRequired
              ? (v) => v!.isEmpty ? 'This field is required' : null
              : null,
    );
  }

  void _showImagePickerOptions(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF252528) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (builder) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(
                  Icons.photo_library_rounded,
                  color: isDark ? Colors.white : Colors.black,
                ),
                title: Text(
                  'Gallery',
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt_rounded,
                  color: isDark ? Colors.white : Colors.black,
                ),
                title: Text(
                  'Camera',
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
