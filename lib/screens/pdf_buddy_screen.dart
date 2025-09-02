import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/pdf_buddy_service.dart';

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

  // Default speech rate is now a more natural 80% speed.
  double _speechRate = 0.8;

  @override
  void initState() {
    super.initState();
    // Set up listeners to update the UI based on TTS events.
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
    _flutterTts.stop(); // Ensure TTS stops when the screen is closed.
    super.dispose();
  }

  /// Handles the entire workflow: picking a PDF, extracting text, and getting a summary.
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

  // --- Text-to-Speech Control Methods ---

  /// Speaks the summary. Handles both starting and resuming.
  Future<void> _speak() async {
    if (_summary.isNotEmpty) {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.speak(_summary);
    }
  }

  /// Pauses the current speech.
  Future<void> _pause() async {
    await _flutterTts.pause();
  }

  /// Stops the current speech completely.
  Future<void> _stop() async {
    await _flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('PDF Study Buddy', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickAndProcessPdf,
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(_isLoading ? 'Processing...' : 'Upload PDF'),
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
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Colors.yellow),
                ),
              ),
            if (!_isLoading && _summary.isEmpty) _buildEmptyState(),
            if (_summary.isNotEmpty) _buildSummaryDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.school_outlined, size: 60, color: Colors.white70),
          const SizedBox(height: 16),
          Text(
            'Upload your lecture notes, articles, or any PDF to get an instant summary and audio lesson!',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _fileName,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white54,
            fontStyle: FontStyle.italic,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          'AI-Generated Summary',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _summary,
            style: GoogleFonts.poppins(
              color: Colors.white.withAlpha(230),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildAudioControls(),
      ],
    );
  }

  Widget _buildAudioControls() {
    return Card(
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Listen to Summary',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // STOP Button
                IconButton(
                  icon: const Icon(Icons.stop_rounded),
                  color: Colors.white,
                  iconSize: 32,
                  tooltip: 'Stop',
                  onPressed: _ttsState == TtsState.stopped ? null : _stop,
                ),
                // PLAY/PAUSE Button
                IconButton(
                  icon: Icon(
                    _ttsState == TtsState.playing
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_filled_rounded,
                  ),
                  color: Colors.yellow,
                  iconSize: 48,
                  tooltip:
                      _ttsState == TtsState.playing ? 'Pause' : 'Play / Resume',
                  onPressed: () {
                    if (_ttsState == TtsState.playing) {
                      _pause();
                    } else {
                      // Handles both 'stopped' and 'paused' states
                      _speak();
                    }
                  },
                ),
              ],
            ),
            // Speech Rate Slider
            Row(
              children: [
                const Icon(
                  Icons.speed_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                Expanded(
                  child: Slider.adaptive(
                    value: _speechRate,
                    min: 0.2,
                    max: 1.0,
                    divisions: 8,
                    activeColor: Colors.yellow,
                    inactiveColor: Colors.grey.shade700,
                    label: "${(_speechRate * 100).toStringAsFixed(0)}%",
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
                Text(
                  '${(_speechRate * 100).toInt()}%',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
