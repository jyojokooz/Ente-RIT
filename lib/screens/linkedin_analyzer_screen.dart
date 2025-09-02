// lib/screens/linkedin_analyzer_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/linkedin_analyzer_service.dart';

class LinkedInAnalyzerScreen extends StatefulWidget {
  const LinkedInAnalyzerScreen({super.key});

  @override
  State<LinkedInAnalyzerScreen> createState() => _LinkedInAnalyzerScreenState();
}

class _LinkedInAnalyzerScreenState extends State<LinkedInAnalyzerScreen> {
  final TextEditingController _textController = TextEditingController();
  final LinkedInAnalyzerService _analyzerService = LinkedInAnalyzerService();

  bool _isLoading = false;
  String? _feedback;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _analyzeProfile() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste your profile summary first.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus(); // Hide keyboard
    setState(() {
      _isLoading = true;
      _feedback = null;
    });

    try {
      final result = await _analyzerService.analyzeProfileText(
        _textController.text,
      );
      setState(() {
        _feedback = result;
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
        title: Text('LinkedIn AI Analyzer', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Get AI-Powered Feedback',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Copy your "About" section from your LinkedIn profile and paste it below to get instant feedback from our career coach AI.',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _textController,
              maxLines: 8,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Paste your LinkedIn summary here...',
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _analyzeProfile,
              icon: const Icon(Icons.analytics_outlined),
              label: Text(_isLoading ? 'Analyzing...' : 'Analyze Profile'),
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
          Text(
            _feedback!,
            // --- THIS IS THE FIX: Replaced withOpacity with withAlpha ---
            style: GoogleFonts.poppins(
              color: Colors.white.withAlpha(230),
              fontSize: 16,
              height: 1.5,
            ),
            // --- END OF FIX ---
          ),
        ],
      ),
    );
  }
}
