import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- Make sure this is imported
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebViewScreen({super.key, required this.url, required this.title});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  final String adBlockerScript = """
    // ... your ad blocker script remains the same ...
  """;

  @override
  void initState() {
    super.initState();

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.black)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (String url) {
                _controller.runJavaScript(adBlockerScript);
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              onWebResourceError: (WebResourceError error) {
                // ... error handling ...
              },

              // --- THIS IS THE UPDATED LOGIC ---
              onNavigationRequest: (NavigationRequest request) {
                final url = request.url;

                // --- CHECK FOR LOGIN AND DOWNLOAD LINKS ---
                const downloadExtensions = ['.pdf', '.zip', '.doc', '.docx'];
                final isDownloadLink = downloadExtensions.any(
                  (ext) => url.toLowerCase().endsWith(ext),
                );

                // Stack Overflow's login page URL and Google's account URL
                final isLoginLink =
                    url.contains('stackoverflow.com/users/login') ||
                    url.contains('accounts.google.com');

                if (isDownloadLink || isLoginLink) {
                  // If it's a download or login link, launch it in the external browser
                  _launchURLInBrowser(url);
                  // And prevent the WebView from trying to handle it
                  return NavigationDecision.prevent;
                }

                // For all other links, let the WebView handle navigation
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.url));
  }

  // Helper function to launch URLs in the default system browser
  Future<void> _launchURLInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            ),
        ],
      ),
    );
  }
}
