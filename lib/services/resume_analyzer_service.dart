// lib/services/resume_analyzer_service.dart

import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ResumeAnalyzerService {
  final String? apiKey = dotenv.env['GEMINI_API_KEY'];

  /// Orchestrates the entire analysis process from a PDF file.
  Future<String> analyzeResume(File pdfFile) async {
    // 1. Extract text from the provided PDF file.
    final resumeText = await _extractTextFromPdf(pdfFile);
    if (resumeText.trim().isEmpty) {
      throw Exception(
        'Could not extract any text from the PDF. Is it a text-based PDF?',
      );
    }

    // 2. Send the extracted text to the AI for analysis.
    return _getAiFeedback(resumeText);
  }

  /// Extracts all readable text from a given PDF file.
  Future<String> _extractTextFromPdf(File pdfFile) async {
    try {
      final List<int> bytes = await pdfFile.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      throw Exception('Failed to read or parse the PDF file: $e');
    }
  }

  /// Sends the extracted resume text to the Gemini API for detailed analysis.
  Future<String> _getAiFeedback(String resumeText) async {
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY not found in .env file.');
    }

    final model = GenerativeModel(
      model: 'gemini-2.5-pro', // Using the best model for in-depth analysis
      apiKey: apiKey!,
    );

    // This comprehensive prompt guides the AI to perform a structured resume review.
    final prompt = '''
    You are an expert career coach and professional resume reviewer for tech roles (like Software Engineer, Data Scientist, etc.). Your task is to analyze the following resume text and provide a detailed, constructive, and encouraging critique.

    Please structure your feedback using the following markdown sections EXACTLY:

    ### **Overall First Impression**
    Start with a brief, 2-3 sentence overview. What is the immediate feeling this resume gives? Is it professional, cluttered, impressive?

    ### **Section-by-Section Analysis**
    Provide specific feedback for each key section of the resume.
    - **Summary/Objective:** Is it concise and impactful? Does it align with a specific career goal?
    - **Experience:** Are the descriptions focused on accomplishments rather than just duties? Do they use strong action verbs (e.g., "Led," "Developed," "Optimized")? Is there quantifiable data (metrics, numbers, percentages)?
    - **Projects:** Are the projects relevant? Do they clearly explain the technology used and the problem solved?
    - **Skills:** Is the skills section well-organized? Does it list relevant technologies?

    ### **Actionable Recommendations**
    - Provide a bulleted list of the top 3-4 most important changes the candidate should make to improve their resume. Be specific. For example, instead of "Improve experience section," say "In your 'Software Engineer Intern' role, rephrase 'Wrote code for the app' to 'Developed a new feature using React that increased user engagement by 15%'."

    ### **ATS (Applicant Tracking System) Friendliness**
    Briefly comment on the resume's format. Is it clean and easily parsable? Does it use standard section headings?

    Maintain a positive and highly constructive tone throughout. The goal is to help the user land their dream job.

    Here is the user's resume text:
    ---
    $resumeText
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
