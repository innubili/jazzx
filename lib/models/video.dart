import '../utils/utils.dart';

/// Users' videos — usually on YouTube
class Video {
  final String id; // The actual URL (desanitized)
  final String title;
  final DateTime date;

  Video({required this.id, required this.title, required this.date});

  /// Constructs a Video from the Firebase-safe key and a map of properties.
  factory Video.fromKeyAndJson(String key, Map<String, dynamic> json) {
    return Video(
      id: desanitizeLinkKey(key),
      title: json['title']?.toString() ?? '',
      date: _parseDate(json['date']),
    );
  }

  /// Converts the Video into a Firebase-safe key and value pair.
  MapEntry<String, Map<String, dynamic>> toKeyAndJson() {
    return MapEntry(sanitizeLinkKey(id), {
      'title': title,
      'date': date.toIso8601String().substring(0, 10).replaceAll('-', ''),
    });
  }

  /// Converts the Video to a regular JSON object (not Firebase key-safe).
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
  };

  /// Handles both YYYYMMDD and ISO8601 formats safely.
  static DateTime _parseDate(dynamic raw) {
    if (raw is String) {
      try {
        if (raw.length == 8 && RegExp(r'^\d{8}$').hasMatch(raw)) {
          final year = int.parse(raw.substring(0, 4));
          final month = int.parse(raw.substring(4, 6));
          final day = int.parse(raw.substring(6, 8));
          return DateTime(year, month, day);
        }
        return DateTime.parse(raw);
      } catch (_) {
        log.warning('⚠️ Invalid date format in video JSON: "$raw"');
      }
    }
    return DateTime(2000); // fallback for null or bad input
  }
}
