// lib/screens/resume_analyzer_screen.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_project/features/tools/resume_analyzer/resume_analyzer_service.dart';

class ResumeAnalyzerScreen extends StatefulWidget {
  const ResumeAnalyzerScreen({super.key});

  @override
  State<ResumeAnalyzerScreen> createState() => _ResumeAnalyzerScreenState();
}

class _ResumeAnalyzerScreenState extends State<ResumeAnalyzerScreen> {
  final ResumeAnalyzerService _analyzerService = ResumeAnalyzerService();

  bool _isLoading = false;
  String? _feedback;
  File? _pickedFile;

  /// Picks a PDF file and triggers the analysis.
  Future<void> _pickAndAnalyzeResume() async {
    // 1. Pick a PDF file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.single.path == null) {
      // User canceled the picker
      return;
    }

    setState(() {
      _pickedFile = File(result.files.single.path!);
      _isLoading = true;
      _feedback = null;
    });

    // 2. Analyze the file
    try {
      final analysisResult = await _analyzerService.analyzeResume(_pickedFile!);
      setState(() {
        _feedback = analysisResult;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('AI Resume Analyzer', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.description_outlined, color: Colors.yellow, size: 60),
            const SizedBox(height: 16),
            Text(
              'Get Your Resume Reviewed',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload your resume in PDF format to get instant, detailed feedback from our AI career coach.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),

            // --- UI CHANGED FROM TEXTFIELD TO UPLOAD BUTTON ---
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickAndAnalyzeResume,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(_isLoading ? 'Analyzing...' : 'Upload Resume (PDF)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_pickedFile != null && !_isLoading)
              Center(
                child: Text(
                  'File: ${_pickedFile!.path.split('/').last}',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              ),

            // --- END OF UI CHANGE ---
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.yellow),
              ),
            if (_feedback != null) _buildFeedbackDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Career Coach Feedback',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.yellow,
            ),
          ),
          const Divider(color: Colors.grey, height: 24),
          // --- Use MarkdownBody to render formatted feedback ---
          MarkdownBody(
            data: _feedback!,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: GoogleFonts.poppins(
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
                height: 1.5,
              ),
              h3: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                height: 2.0,
              ),
              listBullet: GoogleFonts.poppins(
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
