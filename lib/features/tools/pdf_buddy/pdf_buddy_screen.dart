// ===============================
// FILE NAME: pdf_buddy_screen.dart
// FILE PATH: lib/screens/pdf_buddy_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_project/features/tools/pdf_buddy/pdf_buddy_service.dart';

// An enum to manage the state of the Text-to-Speech player.
enum TtsState { playing, stopped, paused }

class PdfBuddyScreen extends StatefulWidget {
  const PdfBuddyScreen({super.key});

  @override
  State<PdfBuddyScreen> createState() => _PdfBuddyScreenState();
}

class _PdfBuddyScreenState extends State<PdfBuddyScreen> {
  final PdfBuddyService _buddyService = PdfBuddyService();
  final FlutterTts _flutterTts = FlutterTts();

  // State variables
  bool _isLoading = false;
  String _summary = '';
  String _fileName = '';
  TtsState _ttsState = TtsState.stopped;

  // Default speech rate
  double _speechRate = 0.8;

  @override
  void initState() {
    super.initState();
    _flutterTts.setStartHandler(
      () => setState(() => _ttsState = TtsState.playing),
    );
    _flutterTts.setCompletionHandler(
      () => setState(() => _ttsState = TtsState.stopped),
    );
    _flutterTts.setPauseHandler(
      () => setState(() => _ttsState = TtsState.paused),
    );
    _flutterTts.setErrorHandler(
      (msg) => setState(() => _ttsState = TtsState.stopped),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _pickAndProcessPdf() async {
    setState(() {
      _isLoading = true;
      _summary = '';
      _fileName = '';
    });
    await _flutterTts.stop();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        setState(() => _fileName = result.files.single.name);

        final extractedText = await _buddyService.extractTextFromPdf(file);
        if (extractedText.trim().isEmpty) {
          throw Exception("Could not find any readable text in the PDF.");
        }

        final summary = await _buddyService.summarizeText(extractedText);
        setState(() => _summary = summary);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- TTS Controls ---
  Future<void> _speak() async {
    if (_summary.isNotEmpty) {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.speak(_summary);
    }
  }

  Future<void> _pause() async {
    await _flutterTts.pause();
  }

  Future<void> _stop() async {
    await _flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlack = Colors.black;
    const Color accentYellow = Colors.yellow;

    return Scaffold(
      backgroundColor: Colors.white, // Modern White Background
      appBar: AppBar(
        title: Text(
          'PDF Study Buddy',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: primaryBlack,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: primaryBlack),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Header Section ---
            Text(
              "Read less,\nlearn more.",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Upload lecture notes or articles to get an instant AI summary and audio lesson.",
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 30),

            // --- Upload Area ---
            GestureDetector(
              onTap: _isLoading ? null : _pickAndProcessPdf,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: _isLoading ? Colors.grey[50] : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isLoading ? Colors.grey[300]! : Colors.black12,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child:
                    _isLoading
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: primaryBlack,
                                strokeWidth: 2.5,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Reading PDF & Summarizing...",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                        : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.upload_file_rounded,
                                size: 32,
                                color: primaryBlack,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Tap to Upload PDF",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryBlack,
                              ),
                            ),
                          ],
                        ),
              ),
            ),

            const SizedBox(height: 40),

            // --- Results Area ---
            if (!_isLoading && _summary.isEmpty && _fileName.isEmpty)
              _buildEmptyState()
            else if (_summary.isNotEmpty)
              _buildSummaryDisplay(primaryBlack, accentYellow),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.library_books_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No document selected yet.',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDisplay(Color primaryColor, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- File Badge ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _fileName,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- Summary Card ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'AI Summary',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Content
              Text(
                _summary,
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // --- Audio Player Card ---
        _buildAudioControls(primaryColor, accentColor),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildAudioControls(Color primaryColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB), // Very light grey
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.headphones_rounded,
                  size: 20,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Listen to Summary',
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Speed Slider
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SPEED: ${(_speechRate * 100).toInt()}%',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                        letterSpacing: 1,
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                      ),
                      child: Slider(
                        value: _speechRate,
                        min: 0.2,
                        max: 1.0,
                        divisions: 8,
                        activeColor: primaryColor,
                        inactiveColor: Colors.grey[300],
                        onChanged: (newRate) {
                          setState(() {
                            _speechRate = newRate;
                            if (_ttsState == TtsState.playing) {
                              _flutterTts.setSpeechRate(_speechRate);
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Controls
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.stop_rounded,
                      color:
                          _ttsState == TtsState.stopped
                              ? Colors.grey[300]
                              : Colors.red[400],
                    ),
                    iconSize: 32,
                    onPressed: _ttsState == TtsState.stopped ? null : _stop,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        _ttsState == TtsState.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      color: Colors.black,
                      iconSize: 32,
                      onPressed: () {
                        if (_ttsState == TtsState.playing) {
                          _pause();
                        } else {
                          _speak();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
