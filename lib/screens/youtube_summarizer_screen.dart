// lib/screens/youtube_summarizer_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/youtube_summarizer_service.dart';
import 'summary_chat_screen.dart';

class YouTubeSummarizerScreen extends StatefulWidget {
  const YouTubeSummarizerScreen({super.key});

  @override
  State<YouTubeSummarizerScreen> createState() =>
      _YouTubeSummarizerScreenState();
}

class _YouTubeSummarizerScreenState extends State<YouTubeSummarizerScreen> {
  final TextEditingController _urlController = TextEditingController();
  final YouTubeSummarizerService _summarizerService =
      YouTubeSummarizerService();

  bool _isLoading = false;
  Map<String, dynamic>? _summaryResult;

  @override
  void dispose() {
    _urlController.dispose();
    _summarizerService.close();
    super.dispose();
  }

  Future<void> _summarizeVideo() async {
    final url = _urlController.text.trim();
    if (!YouTubeSummarizerService.isValidYouTubeUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid YouTube URL.')),
        );
      }
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _summaryResult = null;
    });

    try {
      final result = await _summarizerService.summarizeVideo(url);
      if (mounted) {
        setState(() {
          _summaryResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
          ),
        );
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
        title: Text('YouTube Summarizer', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Paste YouTube video link here...',
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _summarizeVideo,
              icon: const Icon(Icons.summarize_outlined),
              label: Text(_isLoading ? 'Summarizing...' : 'Summarize Video'),
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

            if (_summaryResult != null)
              if (_summaryResult!['success'] == true)
                _buildSummaryDisplay(_summaryResult!)
              else
                _buildErrorDisplay(
                  _summaryResult!['error'] ?? 'An unknown error occurred.',
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDisplay(String error) {
    return Card(
      // --- THIS IS THE FIX: Replaced withOpacity with withAlpha ---
      color: Colors.red.shade900.withAlpha(128), // 128 is 50% opacity
      // --- END OF FIX ---
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              'Failed to Summarize',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.poppins(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryDisplay(Map<String, dynamic> result) {
    final videoDetails = result['videoDetails'] as Map<String, dynamic>;
    final summary = result['summary'] as String;
    final method = result['method'] as String;

    return Column(
      children: [
        _VideoDetailsCard(videoDetails: videoDetails),
        const SizedBox(height: 20),
        Card(
          color: Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'AI-Generated Summary',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.yellow,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        method.contains('transcript')
                            ? 'From Transcript'
                            : 'From Metadata',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor:
                          method.contains('transcript')
                              ? Colors.green.shade800
                              : Colors.blue.shade800,
                    ),
                  ],
                ),
                const Divider(color: Colors.grey, height: 24),
                Text(
                  summary,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withAlpha(230),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => SummaryChatScreen(
                                initialSummary: summary,
                                videoTitle:
                                    videoDetails['title'] ?? 'this video',
                              ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.smart_toy_outlined,
                      color: Colors.yellow,
                    ),
                    label: Text(
                      'Ask Follow-up Questions',
                      style: GoogleFonts.poppins(
                        color: Colors.yellow,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VideoDetailsCard extends StatelessWidget {
  final Map<String, dynamic> videoDetails;
  const _VideoDetailsCard({required this.videoDetails});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (videoDetails['thumbnailUrl'] != null)
            Image.network(
              videoDetails['thumbnailUrl']!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  videoDetails['title'] ?? 'No Title',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  videoDetails['author'] ?? 'Unknown Author',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatChip(
                      Icons.visibility_outlined,
                      '${NumberFormat.compact().format(videoDetails['viewCount'] ?? 0)} views',
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      Icons.timer_outlined,
                      '${videoDetails['duration'] ?? 0} min',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
