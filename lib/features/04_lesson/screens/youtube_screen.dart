import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// 🧩 Model data media (termasuk PDF & YouTube)
class MediaItem {
  final String title;
  final String url;
  final String type; // 'youtube' atau 'pdf'

  MediaItem({
    required this.title,
    required this.url,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'type': type,
      };

  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
        title: json['title'],
        url: json['url'],
        type: json['type'],
      );
}

/// 🎬 Halaman pemutar video YouTube
class YoutubeScreen extends StatefulWidget {
  final String videoUrl;
  const YoutubeScreen({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<YoutubeScreen> createState() => _YoutubeScreenState();
}

class _YoutubeScreenState extends State<YoutubeScreen> {
  YoutubePlayerController? _controller;
  bool _isFullScreen = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    if (videoId == null || videoId.isEmpty) {
      _hasError = true;
      return;
    }
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        enableCaption: true,
      ),
    )..addListener(_onVideoStateChanged);
  }

  void _onVideoStateChanged() {
    final isFullScreenNow = _controller?.value.isFullScreen ?? false;
    if (isFullScreenNow != _isFullScreen) {
      setState(() {
        _isFullScreen = isFullScreenNow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text("Tonton Video")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('ID video YouTube tidak valid atau tautan tidak dikenali.', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                    onPressed: () async {
                    final uri = Uri.tryParse(widget.videoUrl);
                    if (uri != null) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Buka di browser'),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _isFullScreen ? null : AppBar(title: const Text("Tonton Video")),
      body: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _controller!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.deepPurple,
        ),
        builder: (context, player) => player,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }
}
