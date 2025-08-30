import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EtlabWebviewScreen extends StatefulWidget {
  const EtlabWebviewScreen({super.key});

  @override
  State<EtlabWebviewScreen> createState() => _EtlabWebviewScreenState();
}

class _EtlabWebviewScreenState extends State<EtlabWebviewScreen> {
  late final WebViewController _controller;
  var loadingPercentage = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0x00000000))
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                setState(() {
                  loadingPercentage = progress;
                });
              },
              onPageStarted: (String url) {
                setState(() {
                  loadingPercentage = 0;
                });
              },
              onPageFinished: (String url) {
                setState(() {
                  loadingPercentage = 100;
                });
              },
              onWebResourceError: (WebResourceError error) {},
            ),
          )
          ..loadRequest(Uri.parse('https://rit.etlab.in/'));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      // --- UPDATED: Using the new onPopInvokedWithResult callback ---
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        // As before, we check if a pop somehow occurred, and if so, we do nothing.
        if (didPop) {
          return;
        }

        // Check if the webview can go back in its own history.
        if (await _controller.canGoBack()) {
          // If it can, navigate back in the webview.
          _controller.goBack();
        } else {
          // If the webview can't go back, we manually pop the Flutter screen.
          if (context.mounted) {
            // We use Navigator.pop(context) which pops with a null result.
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('RIT ETLab'),
          backgroundColor: Colors.grey.shade900,
          elevation: 1,
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (loadingPercentage < 100)
              LinearProgressIndicator(
                value: loadingPercentage / 100.0,
                backgroundColor: Colors.grey.shade800,
                color: Colors.yellow,
              ),
          ],
        ),
      ),
    );
  }
}
