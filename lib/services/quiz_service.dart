// lib/services/quiz_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:developer';

import '../models/quiz_question.dart';

class QuizService {
  final String? apiKey = dotenv.env['GEMINI_API_KEY'];

  Future<List<QuizQuestion>> generateQuiz({
    required String category,
    int questionCount = 5,
  }) async {
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY not found in .env file.');
    }

    // --- MODEL UPDATED to Gemini 1.5 Pro for higher quality generation ---
    final model = GenerativeModel(model: 'gemini-2.5-pro', apiKey: apiKey!);
    // --- END OF UPDATE ---

    final prompt = '''
    Generate a multiple-choice quiz with $questionCount questions on the topic of "$category".
    The difficulty should be intermediate.
    The response MUST be a valid JSON array. 
    Do not include any introductory text, closing text, or markdown formatting like ```json before or after the JSON array.
    Each object in the array must have the following exact structure:
    {
      "question": "The question text.",
      "options": ["A string for option A", "A string for option B", "A string for option C", "A string for option D"],
      "correctAnswerIndex": an integer from 0 to 3 representing the index of the correct option in the "options" array.
    }
    ''';

    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);

    if (response.text == null) {
      throw Exception(
        'Failed to generate quiz. The AI returned an empty response.',
      );
    }

    // Clean the response just in case the model adds markdown backticks
    final cleanJson =
        response.text!.replaceAll('```json', '').replaceAll('```', '').trim();

    try {
      final List<dynamic> jsonList = json.decode(cleanJson);
      return jsonList.map((json) => QuizQuestion.fromJson(json)).toList();
    } catch (e) {
      // Log the exact response from the AI for easier debugging
      log('--- AI Response Start ---', name: 'QuizService');
      log(
        response.text ?? 'AI returned a null response text.',
        name: 'QuizService',
      );
      log('--- AI Response End ---', name: 'QuizService');
      throw Exception('Failed to parse the quiz JSON from the AI response: $e');
    }
  }
}
