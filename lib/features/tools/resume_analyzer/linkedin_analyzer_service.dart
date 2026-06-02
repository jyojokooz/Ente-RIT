import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class LinkedInAnalyzerService {
  final String? apiKey = dotenv.env['GEMINI_API_KEY'];

  Future<String> analyzeProfileText(String profileText) async {
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY not found in .env file.');
    }

    final model = GenerativeModel(model: 'gemini-1.5-pro', apiKey: apiKey!);

    final prompt = '''
    You are an expert career coach and LinkedIn profile specialist. Your task is to analyze the following LinkedIn "About" section.
    
    ### **Overall Impression**
    Start with a brief, positive overview of the text.
    
    ### **Strengths**
    - Use a bulleted list to highlight 2-3 specific things that are done well.
    
    ### **Areas for Improvement**
    - Use a bulleted list to provide 2-3 specific, constructive suggestions.

    Here is the user's LinkedIn "About" section text:
    ---
    $profileText
    ---
    ''';

    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);

    if (response.text == null) {
      throw Exception(
        'Failed to get analysis from AI. The response was empty.',
      );
    }

    return response.text!;
  }
}
