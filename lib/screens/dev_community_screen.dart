import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:url_launcher/url_launcher.dart'; // <-- FIX: REMOVED THIS UNUSED IMPORT
import '../services/stack_exchange_service.dart';
import 'web_view_screen.dart';

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
    _fetchQuestions();
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
  
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchQuestions(tag: query);
    });
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by tag (e.g., flutter, python)...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none
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
      return const Center(child: CircularProgressIndicator(color: Colors.yellow));
    }
    if (_error.isNotEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Error: $_error', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
      ));
    }
    if (_questions.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? 'Loading latest questions...'
              : 'No questions found for this tag.',
          style: GoogleFonts.poppins(color: Colors.white70)
        )
      );
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(question['score'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                const Text('votes', style: TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
            title: Text(
              question['title']
                .toString()
                .replaceAll('&quot;', '"')
                .replaceAll('&#39;', "'")
                .replaceAll('&amp;', '&'),
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: tags.map((tag) => Chip(
                    label: Text(tag),
                    labelStyle: const TextStyle(fontSize: 10, color: Colors.black),
                    backgroundColor: Colors.yellow,
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(question['answer_count'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const Text('answers', style: TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WebViewScreen(
                    title: 'Stack Overflow',
                    url: question['link'],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}