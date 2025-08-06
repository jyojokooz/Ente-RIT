import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/piston_api_service.dart';

class CodePlaygroundScreen extends StatefulWidget {
  const CodePlaygroundScreen({super.key});

  @override
  State<CodePlaygroundScreen> createState() => _CodePlaygroundScreenState();
}

class _CodePlaygroundScreenState extends State<CodePlaygroundScreen> {
  final _apiService = PistonApiService();
  final _codeController = TextEditingController();

  String _output = 'Your output will appear here...';
  bool _isLoading = false;
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = _apiService.supportedLanguages.keys.first;
    _codeController.text = _getBoilerplateCode(_selectedLanguage);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
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
        return '';
    }
  }

  Future<void> _runCode() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _output = 'Executing...';
    });

    try {
      final result = await _apiService.executeCode(
        _selectedLanguage,
        _codeController.text,
      );
      final runInfo = result['run'];
      if (runInfo != null) {
        // Combine standard output and standard error for a complete console view
        final String stdout = runInfo['stdout'] ?? '';
        final String stderr = runInfo['stderr'] ?? '';
        setState(() {
          _output =
              (stdout.isEmpty && stderr.isEmpty)
                  ? 'Execution finished with no output.'
                  : stdout + stderr;
        });
      } else {
        setState(() {
          _output = result['message'] ?? 'An unknown error occurred.';
        });
      }
    } catch (e) {
      setState(() {
        _output = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Code Playground', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: Column(
        children: [
          _buildControls(),
          // The Code Editor
          Expanded(
            flex: 3, // Give more space to the editor
            child: Container(
              color: const Color(0xFF1E1E1E),
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _codeController,
                style: GoogleFonts.robotoMono(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter your code here...',
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
              ),
            ),
          ),
          // The Output Console
          Expanded(
            flex: 2, // Give less space to the output
            child: Container(
              width: double.infinity,
              color: Colors.grey.shade900,
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Output:',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child:
                          _isLoading
                              ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.yellow,
                                ),
                              )
                              : SelectableText(
                                _output,
                                style: GoogleFonts.robotoMono(
                                  color: Colors.white70,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.grey.shade800,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DropdownButton<String>(
            value: _selectedLanguage,
            dropdownColor: Colors.grey.shade800,
            style: GoogleFonts.poppins(color: Colors.white),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedLanguage = newValue;
                  _codeController.text = _getBoilerplateCode(newValue);
                });
              }
            },
            items:
                _apiService.supportedLanguages.keys
                    .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value[0].toUpperCase() + value.substring(1),
                        ), // Capitalize first letter
                      );
                    })
                    .toList(),
          ),
          ElevatedButton.icon(
            onPressed: _runCode,
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
            label: Text(
              'Run',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
          ),
        ],
      ),
    );
  }
}
