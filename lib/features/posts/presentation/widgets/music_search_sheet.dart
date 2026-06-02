import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

class MusicSearchSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onMusicSelected;

  const MusicSearchSheet({super.key, required this.onMusicSelected});

  @override
  State<MusicSearchSheet> createState() => _MusicSearchSheetState();
}

class _MusicSearchSheetState extends State<MusicSearchSheet> {
  final _searchController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<dynamic> _songs = [];
  bool _isLoading = false;

  String? _currentPreviewUrl;
  bool _isPlaying = false;
  String? _loadingPreviewUrl;

  final List<String> _trendingKeywords = [
    'Top 100',
    'Viral',
    'Pop',
    'Hip Hop',
    'Party',
    'Chill',
    'Love',
    'Workout',
  ];

  @override
  void initState() {
    super.initState();
    _loadTrendingSongs();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadTrendingSongs() {
    final randomKeyword =
        _trendingKeywords[Random().nextInt(_trendingKeywords.length)];
    _searchSongs(randomKeyword);
  }

  Future<void> _searchSongs(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isLoading = true);

    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _currentPreviewUrl = null;
    });

    try {
      final url = Uri.parse(
        'https://itunes.apple.com/search?term=$query&media=music&entity=song&limit=20',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => _songs = data['results']);
      }
    } catch (e) {
      debugPrint("Music API Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePreview(String url) async {
    if (_currentPreviewUrl == url && _isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _loadingPreviewUrl = url);
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
      if (mounted) {
        setState(() {
          _loadingPreviewUrl = null;
          _currentPreviewUrl = url;
          _isPlaying = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Add Music",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Search songs, artists...",
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.grey.shade800,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: _searchSongs,
          ),
          const SizedBox(height: 12),
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.blueAccent,
                      ),
                    )
                    : ListView.builder(
                      itemCount: _songs.length,
                      itemBuilder: (context, index) {
                        final song = _songs[index];
                        final previewUrl = song['previewUrl'];
                        final bool isThisSongLoading =
                            _loadingPreviewUrl == previewUrl;
                        final bool isThisSongPlaying =
                            _currentPreviewUrl == previewUrl && _isPlaying;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                song['artworkUrl100'] ?? '',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (c, e, s) => Container(
                                      color: Colors.grey,
                                      width: 50,
                                      height: 50,
                                    ),
                              ),
                            ),
                            title: Text(
                              song['trackName'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              song['artistName'],
                              maxLines: 1,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                            trailing: SizedBox(
                              width: 40,
                              height: 40,
                              child:
                                  isThisSongLoading
                                      ? const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.blueAccent,
                                        ),
                                      )
                                      : IconButton(
                                        icon: Icon(
                                          isThisSongPlaying
                                              ? Icons.pause_circle_filled
                                              : Icons.play_circle_fill,
                                          color:
                                              isThisSongPlaying
                                                  ? Colors.blueAccent
                                                  : Colors.white54,
                                          size: 32,
                                        ),
                                        onPressed:
                                            () => _togglePreview(previewUrl),
                                      ),
                            ),
                            onTap: () {
                              _audioPlayer.stop();
                              widget.onMusicSelected({
                                'trackName': song['trackName'],
                                'artistName': song['artistName'],
                                'previewUrl': song['previewUrl'],
                                'artworkUrl': song['artworkUrl100'],
                              });
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
