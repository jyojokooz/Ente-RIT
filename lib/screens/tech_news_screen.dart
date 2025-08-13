import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'article_view_screen.dart'; // Import the new screen

// Article model stays the same
class Article {
  final String title;
  final String? description;
  final String url;
  final String? urlToImage;
  final String sourceName;

  Article({
    required this.title,
    this.description,
    required this.url,
    this.urlToImage,
    required this.sourceName,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? 'No Title',
      description: json['description'],
      url: json['url'] ?? '',
      urlToImage: json['urlToImage'],
      sourceName:
          (json['source'] != null && json['source']['name'] != null)
              ? json['source']['name']
              : 'Unknown Source',
    );
  }
}

class TechNewsScreen extends StatefulWidget {
  const TechNewsScreen({super.key});

  @override
  State<TechNewsScreen> createState() => _TechNewsScreenState();
}

class _TechNewsScreenState extends State<TechNewsScreen> {
  late Future<List<Article>> _newsFuture;

  // Get the API key from the environment variables
  final String _apiKey = dotenv.env['NEWS_API_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    _newsFuture = _fetchTechNews();
  }

  Future<List<Article>> _fetchTechNews() async {
    if (_apiKey.isEmpty) {
      debugPrint("API Key not found in .env file.");
      // Throw an error that the FutureBuilder can catch
      throw Exception(
        'API Key is not configured. Please add NEWS_API_KEY to your .env file.',
      );
    }

    final url =
        'https://newsapi.org/v2/top-headlines?country=us&category=technology&apiKey=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> articlesJson = jsonResponse['articles'];
        return articlesJson.map((json) => Article.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load news (Status code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Failed to load news: $e');
    }
  }

  // This method is no longer needed here, it was replaced by the WebView screen.
  // We can remove it to keep the code clean.
  // Future<void> _launchURLInBrowser(String url) async { ... }

  void _openArticleInApp(String url) {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open article, URL is missing.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleViewScreen(articleUrl: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Tech News',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.grey.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Article>>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No news articles found.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            );
          }

          final articles = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return NewsCard(
                article: article,
                // **THE KEY CHANGE IS HERE**
                onTap: () => _openArticleInApp(article.url),
              );
            },
          );
        },
      ),
    );
  }
}

// NewsCard widget stays the same
class NewsCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const NewsCard({super.key, required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // ... no changes needed in the NewsCard widget itself
    return Card(
      color: Colors.grey.shade900,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.urlToImage != null)
              Image.network(
                article.urlToImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 200,
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white30,
                      size: 48,
                    ),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.description ?? 'No description available.',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    article.sourceName,
                    style: GoogleFonts.poppins(
                      color: Colors.yellow,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
