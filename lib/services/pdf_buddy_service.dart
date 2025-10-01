// lib/services/pdf_buddy_service.dart

import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// A service class to handle the logic for the PDF Study Buddy feature.
/// It encapsulates PDF text extraction and AI summarization.
class PdfBuddyService {
  // Load the API key from the .env file.
  final String? apiKey = dotenv.env['GEMINI_API_KEY'];

  /// Extracts all readable text from a given PDF file.
  Future<String> extractTextFromPdf(File pdfFile) async {
    try {
      // Read the PDF file as a list of bytes.
      final List<int> bytes = await pdfFile.readAsBytes();
      // Load the PDF document from the bytes.
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      // Initialize the Syncfusion PDF text extractor.
      final String text = PdfTextExtractor(document).extractText();

      // Dispose the document to release memory. This is important.
      document.dispose();

      return text;
    } catch (e) {
      // If anything goes wrong, throw a more specific exception.
      throw Exception('Failed to extract text from PDF: $e');
    }
  }

  /// Sends a block of text to the Gemini API to be summarized.
  Future<String> summarizeText(String text) async {
    // 1. Validate the API Key
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY not found in .env file.');
    }

    // 2. Truncate the text to a safe limit. 1.5 Pro has a huge context window,
    // but this prevents extremely large/costly requests.
    const int maxChars = 800000;
    final truncatedText =
        text.length > maxChars ? text.substring(0, maxChars) : text;

    // 3. Initialize the Generative Model with the correct, powerful model name
    // --- MODEL UPDATED for consistency and correctness ---
    final model = GenerativeModel(model: 'gemini-2.5-pro', apiKey: apiKey!);
    // --- END OF UPDATE ---

    // 4. Craft a detailed prompt to guide the AI's response.
    final prompt = '''
    You are a helpful and intelligent study assistant. Your task is to analyze the following text, which was extracted from a PDF document, and provide a concise, easy-to-understand summary.
    
    Please adhere to the following instructions:
    - Focus on the key points, main arguments, and important concepts presented in the text.
    - Structure the summary with clear headings (using markdown like ## Heading) and bullet points (using -) for maximum readability.
    - Explain complex topics in simple terms.
    - Do not add any introductory or concluding phrases like "Here is the summary of the text provided". Begin the summary directly.
    
    Here is the text to summarize:
    
    "$truncatedText"
    ''';

    // 5. Send the prompt to the API
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);

    // 6. Validate and return the response
    if (response.text == null) {
      throw Exception(
        'Failed to get a valid summary from the AI. The response was empty.',
      );
    }

    return response.text!;
  }
}
