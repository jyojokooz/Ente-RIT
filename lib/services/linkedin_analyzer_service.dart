// lib/services/linkedin_analyzer_service.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class LinkedInAnalyzerService {
  final String? apiKey = dotenv.env['GEMINI_API_KEY'];

  /// Sends a user's LinkedIn profile text to the Gemini API for analysis.
  ///
  /// Returns a [String] containing formatted, actionable feedback.
  Future<String> analyzeProfileText(String profileText) async {
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY not found in .env file.');
    }

    final model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey!,
    );

    // This detailed prompt guides the AI to act as a helpful career coach.
    final prompt = '''
    You are an expert career coach and LinkedIn profile specialist. Your task is to analyze the following LinkedIn "About" section, likely from a student or recent graduate, and provide encouraging, actionable feedback.

    Please structure your feedback with the following markdown sections:
    
    ### **Overall Impression**
    Start with a brief, positive overview of the text.
    
    ### **Strengths**
    - Use a bulleted list to highlight 2-3 specific things that are done well (e.g., clear career goals, strong action verbs, good project descriptions).
    
    ### **Areas for Improvement**
    - Use a bulleted list to provide 2-3 specific, constructive suggestions. Focus on areas like:
      - **Impact & Metrics:** Suggesting where to add numbers or quantifiable results (e.g., "Increased efficiency by 20%").
      - **Clarity & Conciseness:** Recommending how to make sentences shorter or more direct.
      - **Keywords:** Suggesting relevant industry keywords to improve search visibility.
      - **Call to Action:** Recommending a concluding sentence that invites connection or discussion.

    ### **Example Rewrite**
    Provide a short, rewritten version of one or two sentences from the original text to demonstrate your suggestions.

    Maintain a positive and encouraging tone throughout. Do not be harsh.

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
