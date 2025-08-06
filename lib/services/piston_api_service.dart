import 'dart:convert';
import 'package:http/http.dart' as http;

class PistonApiService {
  final String _baseUrl = 'https://emkc.org/api/v2/piston';

  // A map of supported languages and their latest stable versions
  // You can find more on the Piston GitHub page
  final Map<String, String> supportedLanguages = {
    'python': '3.10.0',
    'javascript': '18.15.0',
    'java': '15.0.2',
    'c++': '10.2.0', // Corresponds to 'cpp' in the API
    'c': '10.2.0',
    'go': '1.16.2',
    'ruby': '3.0.1',
    'php': '8.2.3',
    'swift': '5.3.3',
    'kotlin': '1.8.20',
  };

  Future<Map<String, dynamic>> executeCode(String language, String code) async {
    final languageVersion = supportedLanguages[language.toLowerCase()];
    if (languageVersion == null) {
      throw Exception('Unsupported language: $language');
    }

    // The Piston API expects the language name for C++ to be 'cpp'
    final apiLanguage =
        language.toLowerCase() == 'c++' ? 'cpp' : language.toLowerCase();

    final response = await http.post(
      Uri.parse('$_baseUrl/execute'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'language': apiLanguage,
        'version': languageVersion,
        'files': [
          {'content': code},
        ],
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // Try to decode the error message from the API
      try {
        final error = jsonDecode(response.body)['message'];
        throw Exception('API Error: $error');
      } catch (_) {
        throw Exception(
          'Failed to execute code. Status code: ${response.statusCode}',
        );
      }
    }
  }
}
