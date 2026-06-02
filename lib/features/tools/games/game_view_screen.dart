import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GameViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const GameViewScreen({super.key, required this.url, required this.title});

  @override
  State<GameViewScreen> createState() => _GameViewScreenState();
}

class _GameViewScreenState extends State<GameViewScreen> {
  late final WebViewController _controller;
  bool _isLoadingPage = true; // State to manage loading overlay

  @override
  void initState() {
    super.initState();

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          // Set the WebView's internal background to transparent
          // so our Scaffold color shows through initially.
          ..setBackgroundColor(const Color(0x00000000))
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (String url) {
                if (mounted) {
                  // Once the page is loaded, hide our loading overlay
                  setState(() {
                    _isLoadingPage = false;
                  });
                }
              },
              onWebResourceError: (WebResourceError error) {
                // Handle errors if the page fails to load
                if (mounted) {
                  setState(() {
                    _isLoadingPage = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Failed to load game: ${error.description}",
                      ),
                    ),
                  );
                }
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    const Color brandColor = Colors.yellow;

    return Scaffold(
      // The Scaffold background is our brand color, visible during loading
      backgroundColor: brandColor,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(color: Colors.black),
        ),
        backgroundColor: brandColor, // AppBar matches
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          // The WebView is always in the stack
          WebViewWidget(controller: _controller),

          // --- THE BRANDED LOADING OVERLAY ---
          // This will be visible on top of the WebView until the page is loaded
          if (_isLoadingPage)
            Container(
              color: brandColor, // The same yellow background
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // You can add your app's logo here for a more professional look
                    // Image.asset('assets/logo.png', height: 80),
                    // const SizedBox(height: 20),
                    const CircularProgressIndicator(
                      color: Colors.black, // Black spinner on yellow background
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Loading Game...',
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 16,
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
}
