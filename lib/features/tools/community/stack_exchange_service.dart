import 'dart:convert';
import 'package:http/http.dart' as http;

class StackExchangeService {
  final String _baseUrl = 'https://api.stackexchange.com/2.3';

  // Fetches questions from Stack Overflow. Can be filtered by a tag.
  Future<List<dynamic>> fetchQuestions({String? tag}) async {
    String url =
        '$_baseUrl/questions?order=desc&sort=activity&site=stackoverflow';
    if (tag != null && tag.trim().isNotEmpty) {
      url += '&tagged=${tag.trim().toLowerCase()}';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // The questions are inside the 'items' list
        return data['items'] as List<dynamic>;
      } else {
        throw Exception(
          'Failed to load questions. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to the API: ${e.toString()}');
    }
  }
}
