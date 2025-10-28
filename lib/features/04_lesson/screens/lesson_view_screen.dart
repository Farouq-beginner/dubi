// screens/lesson_view_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import '../../../core/models/lesson_model.dart';

class LessonViewScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonViewScreen({super.key, required this.lesson});

  @override
  State<LessonViewScreen> createState() => _LessonViewScreenState();
}

class _LessonViewScreenState extends State<LessonViewScreen> {
  VideoPlayerController? _vpController;
  ChewieController? _chewieController;
  WebViewController? _webViewController; // for Google Drive preview fallback
  bool _isLoading = false;
  String? _loadError;
  bool _showPreview = true;

  @override
  void initState() {
    super.initState();
    // Lazy-load: prepare actual player after user taps the preview
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _vpController?.dispose();
    super.dispose();
  }

  // Fallback: buka URL di aplikasi eksternal bila bukan YouTube
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak bisa membuka $urlString')), 
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Materi: ${lesson.title}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (lesson.contentType == 'video')
              _buildVideoContent()
            else if (lesson.contentType == 'pdf')
              _buildPdfContent()
            else
              _buildTextContent(),
          ],
        ),
      ),
    );
  }

  // === VIDEO (YouTube) ===
  Widget _buildVideoContent() {
    final url = widget.lesson.contentBody ?? '';
    if (_showPreview) return _buildVideoPreview(url);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Generic network video via Chewie/VideoPlayer
    if (_chewieController != null && _vpController != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: _vpController!.value.aspectRatio == 0
                  ? 16 / 9
                  : _vpController!.value.aspectRatio,
              child: Chewie(controller: _chewieController!),
            ),
          ),
          const SizedBox(height: 8),
          Text('Video dari tautan diputar langsung', style: TextStyle(color: Colors.grey[700])),
        ],
      );
    }

    // WebView fallback (e.g., Google Drive preview)
    if (_webViewController != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: WebViewWidget(controller: _webViewController!),
        ),
      );
    }

    // Tautan tidak dapat diputar langsung: tampilkan pesan + tombol buka eksternal
    return Center(
      child: Column(
        children: [
          Icon(Icons.video_library, size: 96, color: Colors.green[700]),
          const SizedBox(height: 12),
          Text(
            _loadError ?? 'Tautan video tidak dapat diputar langsung. Buka di aplikasi lain.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _launchURL(url),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            label: const Text('BUKA VIDEO', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // Preview kartu dengan thumbnail + tombol play
  Widget _buildVideoPreview(String url) {
  _extractYouTubeId(url); // compute to reuse helper if needed later

    final Widget image = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey.shade700, Colors.blueGrey.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_fill, color: Colors.white70, size: 64),
            const SizedBox(height: 6),
            Text(
              Uri.tryParse(url)?.host ?? 'Link video',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            )
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _showPreview = false;
              _isLoading = true;
            });
            _prepareVideo().whenComplete(() {
              if (mounted) setState(() => _isLoading = false);
            });
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  image,
                  Container(color: Colors.black26),
                  Center(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.play_arrow, color: Colors.red.shade600, size: 40),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Ketuk untuk memutar', style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }

  // === PDF ===
  Widget _buildPdfContent() {
    final url = widget.lesson.contentBody ?? '';
    if (url.isEmpty) {
      return const Text('Link PDF belum tersedia.');
    }
    // Platform-aware handling: PDF viewer plugin works on Android/iOS. For others or non-HTTPS, fallback.
    final scheme = Uri.tryParse(url)?.scheme.toLowerCase();
    final isSecure = scheme == 'https';
    final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

    if (!isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Text(
              'Penampil PDF internal tidak tersedia pada platform ini. Buka PDF di aplikasi/browser.',
              style: TextStyle(color: Colors.orange),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _launchURL(url),
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            label: const Text('BUKA PDF', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      );
    }

    if (!isSecure) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: const Text(
              'Link PDF tidak aman (HTTP). Silakan gunakan HTTPS atau buka di browser.',
              style: TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _launchURL(url),
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            label: const Text('BUKA DI BROWSER', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      );
    }

    final double viewerHeight = MediaQuery.of(context).size.height * 0.75;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: viewerHeight,
        width: double.infinity,
        child: PDF().fromUrl(
          url,
          placeholder: (progress) => Center(
            child: Text('Memuat PDF... ${progress.toStringAsFixed(0)}%'),
          ),
          errorWidget: (error) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Gagal memuat PDF: $error'),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _launchURL(url),
                  icon: const Icon(Icons.open_in_new, color: Colors.white),
                  label: const Text('BUKA DI BROWSER', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // === TEXT ===
  Widget _buildTextContent() {
    return Text(
      widget.lesson.contentBody ?? 'Konten teks belum tersedia.',
      style: const TextStyle(fontSize: 16, height: 1.5),
      softWrap: true,
    );
  }

  // --- Helper: ekstrak ID YouTube dari berbagai format URL ---
  String? _extractYouTubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // youtu.be/<id>
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    // youtube.com/watch?v=<id>
    if (uri.host.contains('youtube.com')) {
      final v = uri.queryParameters['v'];
      if (v != null && v.isNotEmpty) return v;
      // youtube.com/shorts/<id> or /embed/<id>
      if (uri.pathSegments.length >= 2 &&
          (uri.pathSegments.first == 'shorts' || uri.pathSegments.first == 'embed')) {
        return uri.pathSegments[1];
      }
    }
    return null;
  }

  bool _isYouTubeUrl(String url) => _extractYouTubeId(url) != null;

  bool _isGoogleDriveUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.host.contains('drive.google.com') && uri.pathSegments.contains('file');
  }

  String? _drivePreviewUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    // Expecting /file/d/<ID>/view or similar
    final segs = uri.pathSegments;
    final dIndex = segs.indexOf('d');
    if (dIndex != -1 && dIndex + 1 < segs.length) {
      final id = segs[dIndex + 1];
      return 'https://drive.google.com/file/d/$id/preview';
    }
    return null;
  }

  Future<void> _prepareVideo() async {
    if (widget.lesson.contentType != 'video') return;
    final url = widget.lesson.contentBody ?? '';
    if (url.isEmpty) return;

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      if (_isYouTubeUrl(url)) {
        // Tidak mendukung URL YouTube: tampilkan pesan
        _loadError = 'URL YouTube tidak didukung. Gunakan tautan MP4 langsung.';
      } else {
        // First, try native video playback
        _vpController = VideoPlayerController.networkUrl(Uri.parse(url));
        await _vpController!.initialize();
        _chewieController = ChewieController(
          videoPlayerController: _vpController!,
          autoPlay: false,
          looping: false,
          allowFullScreen: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: Colors.green,
            handleColor: Colors.green.shade700,
            bufferedColor: Colors.grey.shade400,
            backgroundColor: Colors.grey.shade300,
          ),
        );
      }
    } catch (e) {
      // If native playback fails and it's a Google Drive link, use WebView preview
      if (_isGoogleDriveUrl(url)) {
        final preview = _drivePreviewUrl(url);
        if (preview != null) {
          _webViewController = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadRequest(Uri.parse(preview));
        } else {
          _loadError = 'Gagal menyiapkan video Google Drive.';
        }
      } else {
        _loadError = 'Format video tidak didukung atau memerlukan autentikasi.';
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}