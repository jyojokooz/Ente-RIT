import 'dart:convert'; // For json.decode/encode
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http; // For making API calls
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeSummarizerService {
  final String? geminiApiKey = dotenv.env['GEMINI_API_KEY'];
  final String? serperApiKey = dotenv.env['SERPER_API_KEY'];
  final YoutubeExplode _yt = YoutubeExplode();

  /// Enhanced method to get video details with transcript availability check
  Future<Map<String, dynamic>> getVideoDetails(String videoUrl) async {
    try {
      var video = await _yt.videos.get(videoUrl);

      bool hasTranscript = await _checkTranscriptAvailability(videoUrl);

      return {
        'title': video.title,
        'thumbnailUrl': video.thumbnails.highResUrl,
        'duration': video.duration?.inMinutes ?? 0,
        'hasTranscript': hasTranscript,
        'description': video.description,
        'author': video.author,
        'viewCount': video.engagement.viewCount,
      };
    } catch (e) {
      throw Exception('Failed to fetch video details: ${e.toString()}');
    }
  }

  /// Check if transcript is available
  Future<bool> _checkTranscriptAvailability(String videoUrl) async {
    try {
      var manifest = await _yt.videos.closedCaptions.getManifest(videoUrl);
      return manifest.tracks.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get transcript if available
  Future<String?> getTranscript(String videoUrl) async {
    try {
      var manifest = await _yt.videos.closedCaptions.getManifest(videoUrl);

      if (manifest.tracks.isEmpty) {
        return null;
      }

      var trackInfo =
          manifest.getByLanguage('en').firstOrNull ?? manifest.tracks.first;
      var captions = await _yt.videos.closedCaptions.get(trackInfo);

      return captions.captions.map((caption) => caption.text).join(' ');
    } catch (e) {
      return null;
    }
  }

  /// Main summarization method that handles both scenarios
  Future<Map<String, dynamic>> summarizeVideo(String videoUrl) async {
    try {
      var videoDetails = await getVideoDetails(videoUrl);
      String videoTitle = videoDetails['title'];
      bool hasTranscript = videoDetails['hasTranscript'];
      String summary;
      String method;

      if (hasTranscript) {
        String? transcript = await getTranscript(videoUrl);
        if (transcript != null && transcript.isNotEmpty) {
          summary = await _summarizeWithTranscript(transcript, videoTitle);
          method = 'transcript';
        } else {
          summary = await _summarizeWithoutTranscript(
            videoUrl,
            videoTitle,
            videoDetails,
          );
          method = 'no_transcript_fallback';
        }
      } else {
        summary = await _summarizeWithoutTranscript(
          videoUrl,
          videoTitle,
          videoDetails,
        );
        method = 'no_transcript';
      }

      return {
        'summary': summary,
        'method': method,
        'videoDetails': videoDetails,
        'success': true,
      };
    } catch (e) {
      return {
        'error': e.toString().replaceFirst("Exception: ", ""),
        'success': false,
      };
    }
  }

  /// Summarize using transcript
  Future<String> _summarizeWithTranscript(
    String transcript,
    String videoTitle,
  ) async {
    if (geminiApiKey == null) {
      throw Exception('GEMINI_API_KEY not found in .env file.');
    }

    final truncatedTranscript =
        transcript.length > 300000
            ? transcript.substring(0, 300000)
            : transcript;

    final model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: geminiApiKey!,
    );

    final prompt = '''
    You are an expert academic assistant. Provide a structured summary of this YouTube video titled "$videoTitle".

    ### **Main Idea**
    A one or two-sentence overview of the video's core message.
    
    ### **Key Takeaways**
    - Use a bulleted list to highlight the 3-5 most important points, arguments, or steps discussed.
    
    ### **Conclusion**
    Brief concluding thoughts or call to action from the video.

    Do not add introductory phrases. Be direct and informative.

    Transcript:
    ---
    $truncatedTranscript
    ---
    ''';

    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);

    if (response.text == null) {
      throw Exception('Failed to get summary from AI.');
    }

    return response.text!;
  }

  /// Summarize without transcript using video metadata
  Future<String> _summarizeWithoutTranscript(
    String videoUrl,
    String videoTitle,
    Map<String, dynamic> videoDetails,
  ) async {
    if (geminiApiKey == null) {
      throw Exception('GEMINI_API_KEY not found in .env file.');
    }

    try {
      String description = videoDetails['description'] ?? '';
      String author = videoDetails['author'] ?? '';
      int duration = videoDetails['duration'] ?? 0;

      String cleanDescription =
          description.length > 2000
              ? '${description.substring(0, 2000)}...'
              : description;

      final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: geminiApiKey!,
      );

      if (cleanDescription.trim().isNotEmpty && cleanDescription.length > 50) {
        final prompt = '''
        Create a comprehensive summary for this YouTube video using the available information:
        
        **Title:** "$videoTitle"
        **Author:** "$author"
        **Duration:** $duration minutes
        **Description:** "$cleanDescription"
        
        Based on the title and description, provide:
        
        ### **Main Topic**
        What this video is primarily about.
        
        ### **Key Points (Inferred)**
        - Extract and list 4-6 main topics or points mentioned in the description.
        
        ### **Target Audience**
        Who would benefit most from watching this video.
        
        ### **Summary Quality Note**
        This summary is based on video metadata only.
        ''';

        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);

        if (response.text != null) {
          return response.text!;
        }
      }

      return _createBasicSummary(
        videoTitle,
        author,
        duration,
        cleanDescription,
      );
    } catch (e) {
      return _createBasicSummary(
        videoTitle,
        videoDetails['author'] ?? 'Unknown',
        videoDetails['duration'] ?? 0,
        'No description available',
      );
    }
  }

  /// Create a basic summary when AI generation fails
  String _createBasicSummary(
    String title,
    String author,
    int duration,
    String description,
  ) {
    final descriptionPreview =
        description.trim().isNotEmpty &&
                description != 'No description available'
            ? '''
**Description Preview:**  
${description.length > 300 ? '${description.substring(0, 300)}...' : description}
'''
            : '';

    return '''
### **Video Overview**
**Title:** $title  
**Creator:** $author  
**Duration:** $duration minutes
### **Available Information**
This video has no captions or detailed metadata.
$descriptionPreview
### **Limitation Notice**
This summary is limited due to reliance on title and basic metadata only.
''';
  }

  /// Answers a follow-up question by first performing a web search for context.
  Future<String> getWebEnhancedAnswer({
    required String videoTitle,
    required String userQuestion,
  }) async {
    if (geminiApiKey == null || serperApiKey == null) {
      throw Exception('API Key not found in .env file.');
    }

    // 1. RETRIEVAL: Perform a web search
    final searchResults = await _searchWeb(videoTitle, userQuestion);

    // 2. AUGMENTED GENERATION: Use search results to answer the question
    final model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: geminiApiKey!,
    );

    final prompt = '''
    You are an expert academic assistant. A user is asking a follow-up question about a YouTube video. Your task is to provide a comprehensive, detailed answer using the provided web search results as your primary source of information.

    **Original Video Topic:** "$videoTitle"
    
    **User's Question:**
    "$userQuestion"

    **Web Search Results (Context):**
    ---
    $searchResults
    ---

    Based on the user's question and the context from the web search results, please generate a detailed and well-structured answer. If the user asks for a "15 mark answer" or something similar, structure it like a university-level exam answer with clear headings, bullet points, and explanations. Be thorough.
    ''';

    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);

    if (response.text == null) {
      throw Exception('The AI could not generate an answer.');
    }

    return response.text!;
  }

  /// Helper method to call the Serper.dev API for web search results.
  Future<String> _searchWeb(String videoTitle, String userQuestion) async {
    final url = Uri.parse('https://google.serper.dev/search');
    final headers = {
      'X-API-KEY': serperApiKey!,
      'Content-Type': 'application/json',
    };
    // Create a smart search query, removing phrases that might confuse the search engine.
    final body = json.encode({
      'q':
          '$videoTitle ${userQuestion.replaceAll("15 marks", "").replaceAll("explain", "")}',
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> organicResults = data['organic'] ?? [];

        // Combine the titles and snippets from the top search results into a single context string.
        return organicResults
            .take(5) // Use top 5 results for context
            .map(
              (result) =>
                  "Title: ${result['title']}\nSnippet: ${result['snippet'] ?? ''}",
            )
            .join('\n\n---\n\n');
      } else {
        return "Web search failed with status code: ${response.statusCode}";
      }
    } catch (e) {
      return "An error occurred during web search: $e";
    }
  }

  /// Extract video ID from various YouTube URL formats
  static String? extractVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  /// Validate YouTube URL
  static bool isValidYouTubeUrl(String url) {
    return extractVideoId(url) != null;
  }

  void close() {
    _yt.close();
  }
}
