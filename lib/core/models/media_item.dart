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
