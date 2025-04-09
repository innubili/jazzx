// users videos usually on Youtbe

class Video {
  final String id; // the URL
  final String title;
  final DateTime date;

  Video({
    required this.id,
    required this.title,
    required this.date,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] ?? '', // Or use the URL as ID directly
      title: json['title'] ?? '',
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
  };
}