import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_project/features/tools/quiz/quiz_question.dart';
import 'package:my_project/features/tools/quiz/quiz_service.dart';
import 'package:my_project/features/tools/quiz/quiz_screen.dart';

/// A screen that displays a grid of available quiz categories for the user to choose from.
class QuizCategoriesScreen extends StatelessWidget {
  const QuizCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the list of quiz categories. You can easily add or remove topics here.
    final List<Map<String, dynamic>> categories = [
      {
        'name': 'C++',
        'icon': Icons.code_rounded,
        'color': Colors.blue.shade400,
      },
      {
        'name': 'Java',
        'icon': Icons.coffee_outlined,
        'color': Colors.orange.shade400,
      },
      {
        'name': 'Python',
        'icon': Icons.merge_type_rounded,
        'color': Colors.green.shade400,
      },
      {
        'name': 'Flutter Widgets',
        'icon': Icons.widgets_outlined,
        'color': Colors.lightBlue.shade400,
      },
      {
        'name': 'Data Structures',
        'icon': Icons.account_tree_outlined,
        'color': Colors.purple.shade400,
      },
      {
        'name': 'Interview Questions',
        'icon': Icons.question_answer_outlined,
        'color': Colors.teal.shade400,
      },
      {
        'name': 'General Knowledge',
        'icon': Icons.public_outlined,
        'color': Colors.redAccent.shade200,
      },
      {
        'name': 'Operating Systems',
        'icon': Icons.memory_rounded,
        'color': Colors.amber.shade600,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Select a Quiz', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _CategoryCard(
            label: category['name'],
            icon: category['icon'],
            color: category['color'],
          );
        },
      ),
    );
  }
}

/// A private helper widget for a single category card.
/// It is a StatefulWidget to manage its own loading state.
class _CategoryCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isLoading = false;
  final QuizService _quizService = QuizService();

  /// Handles the entire process of generating and starting a quiz.
  void _startQuiz() async {
    // Show a loading indicator on this specific card.
    setState(() {
      _isLoading = true;
    });

    try {
      // Call the service to generate questions from the Gemini API.
      final List<QuizQuestion> questions = await _quizService.generateQuiz(
        category: widget.label,
      );

      // If successful and the widget is still on screen, navigate to the quiz.
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    QuizScreen(questions: questions, category: widget.label),
          ),
        );
      }
    } catch (e) {
      // If an error occurs, show a message to the user.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade900,
            content: Text(
              'Error generating quiz: ${e.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      // Always hide the loading indicator, even if an error occurred.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: _isLoading ? null : _startQuiz,
        borderRadius: BorderRadius.circular(16),
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.yellow),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, size: 50, color: widget.color),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        widget.label,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
