import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_project/features/tools/quiz/quiz_question.dart';
import 'package:my_project/features/tools/quiz/quiz_result_screen.dart';

/// The main screen where the user takes the quiz.
/// It displays one question at a time and tracks the user's score.
class QuizScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final String category;

  const QuizScreen({
    super.key,
    required this.questions,
    required this.category,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswerIndex;
  bool _answered = false;

  /// Moves to the next question or finishes the quiz if it's the last question.
  void _nextQuestion() {
    // Check if there are more questions left.
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        // Reset the state for the new question.
        _selectedAnswerIndex = null;
        _answered = false;
      });
    } else {
      // If it's the last question, navigate to the results screen.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => QuizResultScreen(
                score: _score,
                totalQuestions: widget.questions.length,
              ),
        ),
      );
    }
  }

  /// Processes the user's selected answer.
  void _handleAnswer(int index) {
    // Prevent the user from changing their answer once selected.
    if (_answered) return;

    setState(() {
      _selectedAnswerIndex = index;
      _answered = true;
      // Check if the selected answer is correct and update the score.
      if (index == widget.questions[_currentIndex].correctAnswerIndex) {
        _score++;
      }
    });
  }

  /// Determines the color of an answer option based on its state.
  Color _getOptionColor(int index) {
    // If the question hasn't been answered yet, all options are grey.
    if (!_answered) return Colors.grey.shade800;

    // If the question has been answered:
    // The correct answer is always green.
    if (index == widget.questions[_currentIndex].correctAnswerIndex) {
      return Colors.green.shade700;
    }
    // If this option was the one the user selected and it's wrong, it's red.
    else if (index == _selectedAnswerIndex) {
      return Colors.red.shade700;
    }
    // All other incorrect options remain grey.
    return Colors.grey.shade800;
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.questions[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.category, style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
        // Prevent the user from going back during the quiz.
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Progress Indicator ---
            Text(
              'Question ${_currentIndex + 1}/${widget.questions.length}',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // --- Question Text ---
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                currentQuestion.question,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Answer Options ---
            // Use a spread operator to generate a list of Card widgets.
            ...List.generate(currentQuestion.options.length, (index) {
              return Card(
                color: _getOptionColor(index),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  onTap: () => _handleAnswer(index),
                  title: Text(
                    currentQuestion.options[index],
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }),

            // Spacer pushes the button to the bottom.
            const Spacer(),

            // --- Next/Finish Button ---
            ElevatedButton(
              // The button is disabled until an answer is selected.
              onPressed: _answered ? _nextQuestion : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                disabledBackgroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                // Dynamically change the button text on the last question.
                _currentIndex < widget.questions.length - 1
                    ? 'Next Question'
                    : 'Finish Quiz',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
