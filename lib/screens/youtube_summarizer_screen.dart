// ===============================
// FILE NAME: youtube_summarizer_screen.dart
// FILE PATH: lib/screens/youtube_summarizer_screen.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  Future<void> _pasteFromClipboard() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      setState(() {
        _urlController.text = data.text!;
      });
    }
  }

  Future<void> _summarizeVideo() async {
    final url = _urlController.text.trim();
    if (!YouTubeSummarizerService.isValidYouTubeUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid YouTube URL', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToChat() {
    if (_summaryResult == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SummaryChatScreen(
              initialSummary: _summaryResult!['summary'],
              videoTitle: _summaryResult!['videoDetails']['title'] ?? 'Video',
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Red accent color for YouTube vibe
    const Color accentColor = Color(0xFFFF0000);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'AI Video Summarizer',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton:
          (_summaryResult != null && !_isLoading)
              ? FloatingActionButton.extended(
                onPressed: _navigateToChat,
                backgroundColor: Colors.white,
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.black,
                ),
                label: Text(
                  "Chat with Video",
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Header Section ---
            Text(
              "Turn long videos\ninto short notes.",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Paste a YouTube link below to get a summary, key takeaways, and chat with the content.",
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 30),

            // --- Input Field ---
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[800]!),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.link, color: Colors.white54),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Paste YouTube Link",
                        hintStyle: GoogleFonts.poppins(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(
                      Icons.content_paste_rounded,
                      color: accentColor,
                    ),
                    tooltip: "Paste",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Action Button ---
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _summarizeVideo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  shadowColor: accentColor.withOpacity(0.4),
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
                          "Summarize Now",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),

            const SizedBox(height: 40),

            // --- Results Area ---
            if (_summaryResult != null && _summaryResult!['success'] == true)
              _buildResultView()
            else if (_summaryResult != null &&
                _summaryResult!['success'] == false)
              _buildErrorCard(_summaryResult!['error']),

            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final video = _summaryResult!['videoDetails'];
    final summary = _summaryResult!['summary'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Video Preview Card ---
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (video['thumbnailUrl'] != null)
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CachedNetworkImage(
                      imageUrl: video['thumbnailUrl'],
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "${video['duration']} min",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video['title'] ?? 'Unknown Title',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      video['author'] ?? 'Unknown Channel',
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // --- Summary Content ---
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.yellow, size: 20),
            const SizedBox(width: 8),
            Text(
              "AI Summary",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: MarkdownBody(
            data: summary,
            styleSheet: MarkdownStyleSheet(
              p: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                height: 1.6,
              ),
              h1: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              h2: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              h3: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              listBullet: GoogleFonts.poppins(color: Colors.white70),
              strong: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.poppins(color: Colors.red[100]),
            ),
          ),
        ],
      ),
    );
  }
}
