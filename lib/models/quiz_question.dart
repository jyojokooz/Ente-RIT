/// A data model class that represents a single multiple-choice quiz question.
class QuizQuestion {
  /// The text of the question.
  final String question;

  /// A list of possible answers. Typically 4 options.
  final List<String> options;

  /// The index (0-3) of the correct answer in the [options] list.
  final int correctAnswerIndex;

  /// Creates an instance of a quiz question.
  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
  });

  /// A factory constructor to create a [QuizQuestion] instance from a JSON map.
  /// This is used to parse the response from the Gemini API.
  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    // Basic validation to ensure the JSON has the expected keys.
    if (json['question'] == null ||
        json['options'] == null ||
        json['correctAnswerIndex'] == null) {
      throw const FormatException("Invalid JSON for QuizQuestion");
    }

    return QuizQuestion(
      question: json['question'] as String,
      // Safely converts the list from the JSON (which is List<dynamic>)
      // into a strongly-typed List<String>.
      options: List<String>.from(json['options']),
      correctAnswerIndex: json['correctAnswerIndex'] as int,
    );
  }
}
