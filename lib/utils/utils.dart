import 'package:logging/logging.dart';

final log = Logger('JazzX');

String logBuffer = '';

const maxLogBufferLength = 100000;

// Helper to get time in HH:mm:ss.SSS format
String _shortTime(DateTime dt) {
  String iso =
      dt.toIso8601String(); // e.g., 2023-10-27T10:30:55.123Z or 2023-10-27T10:30:55.123
  return iso.substring(11, 23); // Extracts HH:mm:ss.SSS
}

T? enumFromString<T extends Enum>(
  String? value,
  List<T> values, {
  T? fallback,
}) {
  if (value == null) return fallback;
  return values.firstWhere(
    (e) => e.name == value,
    orElse: () => fallback ?? values.first,
  );
}

void defLog(String message) {
  logBuffer += '\n${_shortTime(DateTime.now())} $message';
}

// Legacy logging functions - deprecated in favor of structured logging
@Deprecated('Use AppLoggers.error.error() instead')
void defLogErr(String message) {
  logBuffer += '\n${_shortTime(DateTime.now())} ERROR: $message';
}

@Deprecated('Use structured logging instead')
void defLogClear() {
  logBuffer = '';
}

@Deprecated('Use Log Viewer in Admin screen instead')
void defLogShow() {
  // Legacy function - use structured logging instead
}

@Deprecated('Use structured logging instead')
void setupLogging() {
  // Old logging system disabled - use structured logging instead
}

String sanitizeLinkKey(String url) {
  // Percent-encode, then replace '.' with '_' to make the key Firebase-safe
  return Uri.encodeComponent(url).replaceAll('.', '_');
}

String desanitizeLinkKey(String key) {
  // Revert '_' to '.', then decode
  return Uri.decodeComponent(key.replaceAll('_', '.'));
}

Map<String, dynamic> asStringKeyedMap(Object? value) {
  if (value is Map) {
    return Map<String, dynamic>.fromEntries(
      value.entries
          .where((e) => e.key is String)
          .map((e) => MapEntry(e.key as String, e.value)),
    );
  }
  return {};
}

// utils/json_normalizer.dart
dynamic normalizeFirebaseJson(dynamic input) {
  if (input is Map) {
    return {
      for (var entry in input.entries)
        entry.key.toString(): normalizeFirebaseJson(entry.value),
    };
  } else if (input is List) {
    return input.map(normalizeFirebaseJson).toList();
  } else {
    return input;
  }
}

/// Converts a List into a Map< String, dynamic > with string indices ("0", "1", ...)
/// If already a Map, returns it directly.
/// Otherwise, returns an empty Map.
Map<String, dynamic> normalizeMapOrList(dynamic input, {String context = '?'}) {
  if (input is Map) {
    return Map<String, dynamic>.from(input);
  } else if (input is List) {
    //log.warning(
    //  '⚠️ [$context] Converting List -> Map with ${input.length} entries',
    //);
    return {
      for (int i = 0; i < input.length; i++)
        if (input[i] != null) i.toString(): input[i],
    };
  } else {
    log.warning('⚠️ [$context] Not a Map or List: ${input.runtimeType}');
    return {};
  }
}

/// Converts a JSON-serializable object (Map or List) into a user-readable string for logging.
/// Fields are indexed and indented for clarity, printed inline as 'field: value'.
String prettyPrintJson(dynamic json, {int indent = 1}) {
  final StringBuffer sb = StringBuffer();
  final String tab = '\t' * indent;
  if (json is Map) {
    int idx = 0;
    for (var entry in json.entries) {
      if (entry.value is Map || entry.value is List) {
        sb.writeln('$tab[$idx] ${entry.key}:');
        sb.write(prettyPrintJson(entry.value, indent: indent + 1));
      } else {
        sb.writeln('$tab[$idx] ${entry.key}: ${entry.value}');
      }
      idx++;
    }
  } else if (json is List) {
    for (int i = 0; i < json.length; i++) {
      if (json[i] is Map || json[i] is List) {
        sb.writeln('$tab[$i]:');
        sb.write(prettyPrintJson(json[i], indent: indent + 1));
      } else {
        sb.writeln('$tab[$i]: ${json[i]}');
      }
    }
  } else {
    sb.writeln('$tab$json');
  }
  return sb.toString();
}

/// Formats a DateTime relative to now for display in draft session dialogs
String formatSessionDateTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} minutes ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hours ago';
  } else {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Formats duration in seconds to a human-readable string
String formatDurationHuman(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remainingSeconds = seconds % 60;

  if (hours > 0) {
    return '${hours}h ${minutes}m ${remainingSeconds}s';
  } else if (minutes > 0) {
    return '${minutes}m ${remainingSeconds}s';
  } else {
    return '${remainingSeconds}s';
  }
}
