import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/stack_exchange_service.dart';

class DevCommunityScreen extends StatefulWidget {
  const DevCommunityScreen({super.key});

  @override
  State<DevCommunityScreen> createState() => _DevCommunityScreenState();
}

class _DevCommunityScreenState extends State<DevCommunityScreen> {
  final _apiService = StackExchangeService();
  final _searchController = TextEditingController();
  List<dynamic> _questions = [];
  bool _isLoading = true;
  String _error = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchQuestions(); // Fetch initial questions when the screen loads
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchQuestions({String? tag}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final questions = await _apiService.fetchQuestions(tag: tag);
      if (mounted) {
        setState(() {
          _questions = questions;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // This prevents spamming the API on every keystroke
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchQuestions(tag: query);
    });
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open link.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Dev Community', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by tag (e.g., flutter, python)...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.yellow),
      );
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Text(
          'Error: $_error',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (_questions.isEmpty) {
      return const Center(child: Text('No questions found for this tag.'));
    }

    return ListView.builder(
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        final question = _questions[index];
        final List<dynamic> tags = question['tags'] ?? [];

        return Card(
          color: Colors.grey.shade900,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  question['score'].toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Text('votes', style: TextStyle(fontSize: 10)),
              ],
            ),
            title: Text(question['title'] ?? 'No Title'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4.0,
                  runSpacing: 4.0,
                  children:
                      tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  question['answer_count'].toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text('answers', style: TextStyle(fontSize: 10)),
              ],
            ),
            onTap: () => _launchURL(question['link']),
          ),
        );
      },
    );
  }
}
