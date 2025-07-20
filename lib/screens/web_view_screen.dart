import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- 1. ADD THIS IMPORT
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
                  setState(() => _isLoading = false);
                }
              },
              onWebResourceError: (WebResourceError error) {
                // ... error handling ...
              },

              // --- 2. ADD THE NAVIGATION INTERCEPTOR ---
              onNavigationRequest: (NavigationRequest request) {
                final url = request.url;
                // List of common file extensions that should trigger a download
                const downloadExtensions = [
                  '.pdf',
                  '.zip',
                  '.doc',
                  '.docx',
                  '.xls',
                  '.xlsx',
                  '.ppt',
                  '.pptx',
                  '.apk',
                ];

                // Check if the URL ends with a downloadable file extension
                if (downloadExtensions.any(
                  (ext) => url.toLowerCase().endsWith(ext),
                )) {
                  // If it's a download link, launch it in an external browser
                  _launchURLInBrowser(url);
                  // And prevent the WebView from trying to navigate to it
                  return NavigationDecision.prevent;
                }

                // For all other links, let the WebView handle it normally
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.url));
  }

  // --- 3. ADD THE HELPER FUNCTION TO LAUNCH URLS ---
  Future<void> _launchURLInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      // mode: LaunchMode.externalApplication is crucial.
      // It forces the link to open in the default browser (Chrome, Safari)
      // instead of an in-app browser view.
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
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
