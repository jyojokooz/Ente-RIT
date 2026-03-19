// ===============================
// FILE NAME: story_creator_screen.dart
// FILE PATH: lib/screens/stories/story_creator_screen.dart
// ===============================

import 'dart:io';
import 'package:flutter/material.dart';

import 'story_gallery_view.dart';
import 'story_editor_view.dart';

class StoryCreatorScreen extends StatefulWidget {
  const StoryCreatorScreen({super.key});

  @override
  State<StoryCreatorScreen> createState() => _StoryCreatorScreenState();
}

class _StoryCreatorScreenState extends State<StoryCreatorScreen> {
  // 0: Gallery, 1: Editor
  int _currentStep = 0;
  List<File> _preparedFiles = [];

  void _onFilesSelected(List<File> files) {
    setState(() {
      _preparedFiles = files;
      _currentStep = 1;
    });
  }

  void _onBackToGallery() {
    setState(() {
      _preparedFiles.clear();
      _currentStep = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body:
          _currentStep == 0
              ? StoryGalleryView(
                onFilesSelected: _onFilesSelected,
                onCancel: () => Navigator.pop(context),
              )
              : StoryEditorView(
                files: _preparedFiles,
                onBack: _onBackToGallery,
                onUploadComplete: () => Navigator.pop(context),
              ),
    );
  }
}
