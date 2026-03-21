// ===============================
// FILE PATH: lib/screens/edit_post_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import the user tagging sheet we created earlier
import 'create_post/user_tagging_sheet.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;
  final String initialCaption;
  final List<String> initialTaggedUsers;

  const EditPostScreen({
    super.key,
    required this.postId,
    required this.initialCaption,
    required this.initialTaggedUsers,
  });

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late final TextEditingController _captionController;
  late List<String> _taggedUsers;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.initialCaption);
    _taggedUsers = List.from(widget.initialTaggedUsers);
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _showTaggingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: UserTaggingSheet(
              initialTags: _taggedUsers,
              onSaveTags: (newTags) {
                setState(() {
                  _taggedUsers = newTags;
                });
              },
            ),
          ),
    );
  }

  Future<void> _savePost() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final newCaption = _captionController.text.trim();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId);

      // Update both caption and tagged users
      await postRef.update({
        'caption': newCaption,
        'taggedUsers': _taggedUsers,
      });

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Post updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop(); // Go back to the previous screen
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Edit Post',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _savePost,
              child: Text(
                'Save',
                style: GoogleFonts.poppins(
                  color: Colors.blueAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _captionController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Edit your caption...',
                hintStyle: const TextStyle(color: Colors.white54),
                fillColor: Colors.grey.shade900,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tagging Tile
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.person_add_outlined,
                  color: Colors.white,
                  size: 26,
                ),
                title: Text(
                  _taggedUsers.isEmpty
                      ? "Tag people"
                      : "${_taggedUsers.length} Person tagged",
                  style: GoogleFonts.poppins(
                    color:
                        _taggedUsers.isNotEmpty
                            ? Colors.blueAccent
                            : Colors.white,
                    fontSize: 15,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white54,
                ),
                onTap: _showTaggingSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
