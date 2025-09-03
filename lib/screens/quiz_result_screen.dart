import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_project/screens/pages/classify_screen.dart'; // Import your main screen to navigate back to it.

/// A screen that displays the final score and results of the quiz.
class QuizResultScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate the percentage for a more detailed result if needed.
    final double percentage = (score / totalQuestions) * 100;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Quiz Results', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
        // Prevent the user from manually going back.
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              // Provide a dynamic congratulatory message.
              percentage >= 50 ? 'Congratulations!' : 'Good Effort!',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.yellow,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'You scored',
              style: GoogleFonts.poppins(fontSize: 22, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            // The main score display.
            Text(
              '$score / $totalQuestions',
              style: GoogleFonts.poppins(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 48),
            // The call-to-action button to play again.
            ElevatedButton(
              onPressed: () {
                // This navigation logic is important. It removes all screens
                // from the stack until it finds the first one (your home/main screen)
                // and then replaces it with the ClassifyScreen to avoid a growing
                // back-stack of old quiz screens.
                Navigator.popUntil(context, (route) => route.isFirst);

                // If your ClassifyScreen is the root, you might not even need the pushReplacement.
                // However, this is a safer way to ensure the user lands back on the correct screen.
                // You may need to adjust this if your root widget is something else.
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClassifyScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Play Again',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
