import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

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

final log = Logger('JazzX');

void setupLogging() {
  Logger.root.level = Level.ALL; // Log everything
  Logger.root.onRecord.listen((record) {
    debugPrint(
      '[${record.level.name}] ${record.loggerName}: ${record.message}',
    );
  });
}

String sanitizeLinkKey(String url) {
  return Uri.encodeFull(
    url,
  ).replaceAll('.', '_').replaceAll('#', ' sharp').replaceAll('/', ' over ');
}

String desanitizeLinkKey(String key) {
  return Uri.decodeFull(
    key
        .replaceAll('_', '.')
        .replaceAll(' sharp', '#')
        .replaceAll(' over ', '/'),
  );
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

/// Converts a List into a Map<String, dynamic> with string indices ("0", "1", ...)
/// If already a Map, returns it directly.
/// Otherwise, returns an empty Map.
Map<String, dynamic> normalizeMapOrList(dynamic input, {String context = '?'}) {
  if (input is Map) {
    return Map<String, dynamic>.from(input);
  } else if (input is List) {
    log.warning(
      '⚠️ [$context] Converting List -> Map with ${input.length} entries',
    );
    return {
      for (int i = 0; i < input.length; i++)
        if (input[i] != null) i.toString(): input[i],
    };
  } else {
    log.warning('⚠️ [$context] Not a Map or List: ${input.runtimeType}');
    return {};
  }
}
