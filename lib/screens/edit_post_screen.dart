import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;
  final String initialCaption;

  const EditPostScreen({
    super.key,
    required this.postId,
    required this.initialCaption,
  });

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late final TextEditingController _captionController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.initialCaption);
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _savePost() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final newCaption = _captionController.text.trim();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // Get the reference to the post document and update the caption
      final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
      await postRef.update({'caption': newCaption});

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Post updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop(); // Go back to the home screen
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to update post: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          'Edit Post',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              ),
            )
          else
            TextButton(
              onPressed: _savePost,
              child: Text(
                'Save',
                style: GoogleFonts.poppins(
                  color: Colors.yellow,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _captionController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          maxLines: 8,
          decoration: InputDecoration(
            hintText: 'Edit your caption...',
            hintStyle: const TextStyle(color: Colors.white70),
            fillColor: Colors.grey.shade900,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}