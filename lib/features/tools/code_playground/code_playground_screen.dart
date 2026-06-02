import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/highlight.dart' show Mode;
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:highlight/languages/python.dart';
// --- THIS IS THE CORRECTED LINE ---
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/cpp.dart';

import 'package:my_project/features/tools/code_playground/piston_api_service.dart';

class CodePlaygroundScreen extends StatefulWidget {
  const CodePlaygroundScreen({super.key});

  @override
  State<CodePlaygroundScreen> createState() => _CodePlaygroundScreenState();
}

class _CodePlaygroundScreenState extends State<CodePlaygroundScreen> {
  final _apiService = PistonApiService();
  CodeController? _codeController;

  String _output = 'Your output will appear here...';
  bool _isLoading = false;
  late String _selectedLanguage;

  bool _isInitializing = true;
  static const String _lastLanguageKey = 'last_selected_language';
  String _prefsKeyForLanguage(String lang) => 'code_snippet_$lang';

  final Map<String, Mode> _languageModes = {
    'python': python,
    'javascript': javascript, // This will now be defined correctly
    'java': java,
    'c++': cpp,
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedLanguage =
        prefs.getString(_lastLanguageKey) ??
        _apiService.supportedLanguages.keys.first;
    final savedCode = prefs.getString(_prefsKeyForLanguage(_selectedLanguage));
    _initializeCodeController(
      initialCode: savedCode ?? _getBoilerplateCode(_selectedLanguage),
    );
    setState(() {
      _isInitializing = false;
    });
  }

  void _initializeCodeController({required String initialCode}) {
    final languageMode = _languageModes[_selectedLanguage];
    _codeController = CodeController(text: initialCode, language: languageMode);
  }

  @override
  void dispose() {
    _saveCurrentCode();
    _codeController?.dispose();
    super.dispose();
  }

  Future<void> _saveCurrentCode() async {
    if (_codeController == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKeyForLanguage(_selectedLanguage),
      _codeController!.text,
    );
    await prefs.setString(_lastLanguageKey, _selectedLanguage);
  }

  Future<void> _switchLanguage(String newLanguage) async {
    await _saveCurrentCode();
    setState(() {
      _selectedLanguage = newLanguage;
    });
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefsKeyForLanguage(newLanguage));
    _codeController?.dispose();
    _initializeCodeController(
      initialCode: savedCode ?? _getBoilerplateCode(newLanguage),
    );
    setState(() {});
  }

  String _getBoilerplateCode(String language) {
    switch (language.toLowerCase()) {
      case 'python':
        return 'print("Hello, World!")';
      case 'javascript':
        return 'console.log("Hello, World!");';
      case 'java':
        return 'public class Main {\n    public static void main(String[] args) {\n        System.out.println("Hello, World!");\n    }\n}';
      case 'c++':
        return '#include <iostream>\n\nint main() {\n    std::cout << "Hello, World!";\n    return 0;\n}';
      default:
        return '// Select a language to see boilerplate code';
    }
  }

  Future<void> _runCode() async {
    if (_isLoading || _codeController == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _output = 'Executing...';
    });
    try {
      final result = await _apiService.executeCode(
        _selectedLanguage,
        _codeController!.text,
      );
      final runInfo = result['run'];
      if (runInfo != null) {
        final String stdout = runInfo['stdout'] ?? '';
        final String stderr = runInfo['stderr'] ?? '';
        setState(() {
          _output =
              (stdout.isEmpty && stderr.isEmpty)
                  ? 'Execution finished with no output.'
                  : '$stdout$stderr';
        });
      } else {
        setState(() {
          _output = result['message'] ?? 'An unknown error occurred.';
        });
      }
    } catch (e) {
      setState(() {
        _output = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D2D2D),
      builder: (context) {
        return ListView.builder(
          itemCount: _apiService.supportedLanguages.length,
          itemBuilder: (context, index) {
            final lang = _apiService.supportedLanguages.keys.elementAt(index);
            return ListTile(
              title: Text(
                lang[0].toUpperCase() + lang.substring(1),
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              onTap: () {
                _switchLanguage(lang);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: Text('Code Playground', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
      ),
      body:
          _isInitializing
              ? const Center(
                child: CircularProgressIndicator(color: Colors.greenAccent),
              )
              : Row(
                children: [
                  _buildActivityBar(),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          flex: 3,
                          child:
                              _codeController == null
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : CodeTheme(
                                    data: CodeThemeData(styles: vs2015Theme),
                                    child: CodeField(
                                      controller: _codeController!,
                                      textStyle: GoogleFonts.robotoMono(
                                        fontSize: 14,
                                      ),
                                      expands: true,
                                    ),
                                  ),
                        ),
                        _buildOutputTerminal(),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildActivityBar() {
    return Container(
      width: 60,
      color: const Color(0xFF333333),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.greenAccent,
              size: 30,
            ),
            onPressed: _runCode,
            tooltip: 'Run Code',
          ),
          const SizedBox(height: 20),
          IconButton(
            icon: const Icon(
              Icons.tune_rounded,
              color: Colors.white70,
              size: 28,
            ),
            onPressed: _showLanguageSelector,
            tooltip: 'Change Language',
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              _selectedLanguage.substring(0, 2).toUpperCase(),
              style: GoogleFonts.poppins(
                color: Colors.white38,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputTerminal() {
    return Expanded(
      flex: 2,
      child: Container(
        width: double.infinity,
        color: const Color(0xFF252526),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              color: const Color(0xFF333333),
              child: Text(
                'TERMINAL',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  letterSpacing: 1,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child:
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.greenAccent,
                          ),
                        )
                        : SingleChildScrollView(
                          child: SelectableText(
                            _output,
                            style: GoogleFonts.robotoMono(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
