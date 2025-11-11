import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  late final WebViewController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() {
              _hasError = false;
            });
          },
          onWebResourceError: (error) {
            setState(() {
              _hasError = true;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://ocrticketing-production.up.railway.app/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda')),
      body: _hasError
          ? const Center(
              child: Text(
                '❌ No se pudo cargar la página.\nRevisa tu conexión a internet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            )
          : WebViewWidget(controller: _controller),
    );
  }
}
