import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class PdfScreen extends StatefulWidget {
  final String pdfUrl;
  const PdfScreen({Key? key, required this.pdfUrl}) : super(key: key);

  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  bool _isLoading = true;
  late String viewUrl;

  @override
  void initState() {
    super.initState();
    viewUrl = _convertToViewLink(widget.pdfUrl);
  }

  // 🔹 Ubah link Google Drive ke link tampilan embed
  String _convertToViewLink(String url) {
    if (url.contains('drive.google.com')) {
      final regExp = RegExp(r'/d/([a-zA-Z0-9_-]+)');
      final match = regExp.firstMatch(url);
      if (match != null) {
        final id = match.group(1);
        // Google Docs viewer lebih stabil untuk PDF
        return 'https://drive.google.com/file/d/$id/preview';
      }
    }
    // Kalau bukan dari Drive, buka lewat Google Docs Viewer juga
    return 'https://docs.google.com/gview?embedded=true&url=$url';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lihat PDF'),
        backgroundColor: Colors.deepPurple.shade50,
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(viewUrl)),
            onProgressChanged: (controller, progress) {
              if (progress == 100) {
                setState(() => _isLoading = false);
              }
            },
            onLoadError: (controller, url, code, message) {
              setState(() => _isLoading = false);
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
